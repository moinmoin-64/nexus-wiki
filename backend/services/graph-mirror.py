#!/usr/bin/env python3
"""
Graph Mirror Service
Extracts Wikilinks ([[...]] patterns) from PostgreSQL documents and mirrors them to Neo4j.
Runs as a background service, syncing every GRAPH_SYNC_INTERVAL seconds.
"""

import os
import re
import time
import logging
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor
from neo4j import GraphDatabase, basic_auth
import hashlib

# Configuration
POSTGRES_URL = os.getenv('POSTGRES_URL', 'postgresql://nexus_readonly:@localhost:5432/nexus_db')
NEO4J_BOLT_URL = os.getenv('NEO4J_BOLT_URL', 'bolt://localhost:7687')
NEO4J_USER = os.getenv('NEO4J_USER', 'neo4j')
NEO4J_PASSWORD = os.getenv('NEO4J_PASSWORD', 'neo4j')
GRAPH_SYNC_INTERVAL = int(os.getenv('GRAPH_SYNC_INTERVAL', '300'))

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('GraphMirror')

# Regex for Wikilink extraction: [[Document Title]] or [[path/to/doc]]
WIKILINK_PATTERN = re.compile(r'\[\[([^\]]+)\]\]')

class GraphMirror:
    def __init__(self):
        self.pg_conn = None
        self.neo4j_driver = None
        self.sync_count = 0
        
    def connect(self):
        """Establish connections to PostgreSQL and Neo4j"""
        try:
            # PostgreSQL connection
            self.pg_conn = psycopg2.connect(POSTGRES_URL)
            logger.info("Connected to PostgreSQL")
            
            # Neo4j connection
            self.neo4j_driver = GraphDatabase.driver(
                NEO4J_BOLT_URL,
                auth=basic_auth(NEO4J_USER, NEO4J_PASSWORD)
            )
            self.neo4j_driver.verify_connectivity()
            logger.info("Connected to Neo4j")
            
            # Initialize Neo4j schema
            self._init_neo4j_schema()
            
        except Exception as e:
            logger.error(f"Connection error: {e}")
            raise
    
    def _init_neo4j_schema(self):
        """Create Neo4j constraints and indexes"""
        with self.neo4j_driver.session() as session:
            # Create constraints
            session.run("""
                CREATE CONSTRAINT doc_uuid IF NOT EXISTS 
                FOR (d:Document) REQUIRE d.uuid IS UNIQUE
            """)
            session.run("""
                CREATE CONSTRAINT doc_title IF NOT EXISTS 
                FOR (d:Document) REQUIRE d.title IS NOT NULL
            """)
            
            # Create indexes
            session.run("""
                CREATE INDEX doc_status IF NOT EXISTS 
                FOR (d:Document) ON (d.status)
            """)
            session.run("""
                CREATE INDEX doc_updated IF NOT EXISTS 
                FOR (d:Document) ON (d.updated_at)
            """)
            
            logger.info("Neo4j schema initialized")
    
    def extract_wikilinks(self, markdown_text):
        """Extract all [[wikilinks]] from markdown text"""
        if not markdown_text:
            return []
        matches = WIKILINK_PATTERN.findall(markdown_text)
        return list(set(matches))  # Deduplicate
    
    def sync_documents(self):
        """Sync all documents and links from PostgreSQL to Neo4j"""
        try:
            logger.info(f"Starting sync (iteration #{self.sync_count})...")
            
            with self.pg_conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Fetch all published documents
                cursor.execute("""
                    SELECT id, uuid, title, markdown_raw, status, 
                           created_at, updated_at, tags
                    FROM nexus.documents
                    WHERE status = 'published'
                    ORDER BY updated_at DESC
                """)
                
                documents = cursor.fetchall()
                logger.info(f"Found {len(documents)} published documents")
                
                # Sync each document to Neo4j
                with self.neo4j_driver.session() as neo_session:
                    for doc in documents:
                        self._sync_document(neo_session, doc)
                    
                    # Update link statistics
                    self._update_link_stats(neo_session)
            
            self.sync_count += 1
            logger.info(f"Sync completed successfully (iteration {self.sync_count})")
            
        except Exception as e:
            logger.error(f"Sync error: {e}", exc_info=True)
    
    def _sync_document(self, neo_session, doc):
        """Sync individual document and its links"""
        try:
            # Create or update Document node
            neo_session.run("""
                MERGE (d:Document {uuid: $uuid})
                ON CREATE SET
                    d.title = $title,
                    d.status = $status,
                    d.created_at = $created_at,
                    d.updated_at = $updated_at,
                    d.tags = $tags,
                    d.inlink_count = 0,
                    d.outlink_count = 0
                ON MATCH SET
                    d.title = $title,
                    d.status = $status,
                    d.updated_at = $updated_at,
                    d.tags = $tags
            """, {
                'uuid': str(doc['uuid']),
                'title': doc['title'],
                'status': doc['status'],
                'created_at': doc['created_at'].isoformat() if doc['created_at'] else None,
                'updated_at': doc['updated_at'].isoformat() if doc['updated_at'] else None,
                'tags': doc['tags'] or []
            })
            
            # Extract wikilinks
            wikilinks = self.extract_wikilinks(doc['markdown_raw'])
            
            # Create relationships
            for wikilink in wikilinks:
                neo_session.run("""
                    MATCH (source:Document {uuid: $source_uuid})
                    MATCH (target:Document {title: $target_title})
                    MERGE (source)-[:LINKS_TO]->(target)
                """, {
                    'source_uuid': str(doc['uuid']),
                    'target_title': wikilink
                })
            
            # Count links
            neo_session.run("""
                MATCH (d:Document {uuid: $uuid})
                SET d.outlink_count = size((d)-[:LINKS_TO]->())
            """, {'uuid': str(doc['uuid'])})
            
        except Exception as e:
            logger.error(f"Error syncing document {doc['id']}: {e}")
    
    def _update_link_stats(self, neo_session):
        """Calculate and update inlink counts for all documents"""
        neo_session.run("""
            MATCH (d:Document)
            SET d.inlink_count = size((d)<-[:LINKS_TO]-())
        """)
        
        # Identify hub documents (high centrality)
        neo_session.run("""
            MATCH (d:Document)
            WITH d, d.inlink_count + d.outlink_count as centrality
            SET d.centrality = centrality
        """)
    
    def get_neighborhood(self, doc_uuid, depth=1):
        """Get local neighborhood graph around a document"""
        with self.neo4j_driver.session() as session:
            result = session.run("""
                MATCH (center:Document {uuid: $uuid})
                MATCH path = (center)-[*0.. $depth]-(neighbor:Document)
                RETURN {
                    center: center,
                    neighbors: collect(distinct neighbor),
                    links: collect(distinct {
                        source: startNode(relationships(path)),
                        target: endNode(relationships(path))
                    })
                } as neighborhood
            """, {'uuid': doc_uuid, 'depth': depth})
            
            return result.single()
    
    def search_backlinks(self, target_title):
        """Find all documents that link to a given document"""
        with self.neo4j_driver.session() as session:
            result = session.run("""
                MATCH (source:Document)-[:LINKS_TO]->(target:Document {title: $title})
                RETURN source.title as title, source.uuid as uuid, source.updated_at as updated
                ORDER BY source.updated_at DESC
            """, {'title': target_title})
            
            return [dict(record) for record in result]
    
    def run(self):
        """Main loop - continuously sync"""
        logger.info(f"Graph Mirror starting (sync interval: {GRAPH_SYNC_INTERVAL}s)")
        
        try:
            while True:
                self.sync_documents()
                time.sleep(GRAPH_SYNC_INTERVAL)
        except KeyboardInterrupt:
            logger.info("Shutting down...")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Close all connections"""
        if self.pg_conn:
            self.pg_conn.close()
        if self.neo4j_driver:
            self.neo4j_driver.close()
        logger.info("Connections closed")

if __name__ == '__main__':
    mirror = GraphMirror()
    mirror.connect()
    mirror.run()
