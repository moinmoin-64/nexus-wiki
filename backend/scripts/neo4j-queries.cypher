// Project Nexus - Neo4j Cypher Queries Reference

// ============================================================================
// FUNDAMENTAL QUERIES
// ============================================================================

// List all documents
MATCH (d:Document)
RETURN d.title, d.uuid, d.centrality, d.inlink_count, d.outlink_count
ORDER BY d.updated_at DESC;

// Count total documents
MATCH (d:Document)
RETURN COUNT(d) as total_documents;

// Delete all data (careful!)
MATCH (n)
DETACH DELETE n;

// ============================================================================
// DOCUMENT QUERIES
// ============================================================================

// Find document by title
MATCH (d:Document {title: "API Design"})
RETURN d;

// Find document by UUID
MATCH (d:Document {uuid: "550e8400-e29b-41d4-a716-446655440000"})
RETURN d;

// Find all documents with specific tag
MATCH (d:Document)
WHERE "architecture" IN d.tags
RETURN d.title, d.tags;

// Find recent documents
MATCH (d:Document)
RETURN d.title, d.updated_at
ORDER BY d.updated_at DESC
LIMIT 20;

// ============================================================================
// LINK QUERIES
// ============================================================================

// All outgoing links from a document
MATCH (source:Document {title: "API Design"})-[:LINKS_TO]->(target:Document)
RETURN source.title as from, target.title as to;

// All incoming links (backlinks)
MATCH (source:Document)-[:LINKS_TO]->(target:Document {title: "Database Schema"})
RETURN source.title as from, target.title as to;

// Count links
MATCH (source:Document)-[:LINKS_TO]->(target:Document)
RETURN COUNT(*) as total_links;

// ============================================================================
// CENTRALITY & NETWORK ANALYSIS
// ============================================================================

// Most connected documents (by total links)
MATCH (d:Document)
WITH d, size((d)-[:LINKS_TO]->()) as outlinks, size((d)<-[:LINKS_TO]-()) as inlinks
RETURN d.title, inlinks, outlinks, (inlinks + outlinks) as centrality
ORDER BY centrality DESC
LIMIT 20;

// Find Hub documents (articles linked to most)
MATCH (d:Document)
RETURN d.title, d.inlink_count as inbound_links
ORDER BY inbound_links DESC
LIMIT 10;

// Find Authority documents (link to many others)
MATCH (d:Document)
RETURN d.title, d.outlink_count as outbound_links
ORDER BY outbound_links DESC
LIMIT 10;

// PageRank-like: Documents linked by highly-connected docs
MATCH (hub:Document)-[:LINKS_TO]->(target:Document)
WHERE hub.centrality > 10
RETURN target.title, COUNT(*) as weighted_inlinks
ORDER BY weighted_inlinks DESC
LIMIT 20;

// ============================================================================
// NEIGHBORHOOD QUERIES
// ============================================================================

// Direct neighbors (1 to many links)
MATCH (center:Document {title: "API Design"})-[r:LINKS_TO]-(neighbor:Document)
RETURN center.title as center, neighbor.title as neighbor, TYPE(r) as relationship;

// 2-hop neighborhood (distance 2)
MATCH (center:Document {title: "API Design"})-[*1..2]-(neighbor:Document)
RETURN center.title, neighbor.title, distance(center, neighbor) as distance;

// All paths from one document to another
MATCH path = (source:Document {title: "API Design"})-[:LINKS_TO*1..5]->(target:Document {title: "Database Schema"})
RETURN [node IN nodes(path) | node.title] as path_titles
LIMIT 5;

// Find indirect connections (no direct link but connected through intermediaries)
MATCH (a:Document {title: "Frontend"})-[:LINKS_TO*2]-(b:Document {title: "Infrastructure"})
WHERE NOT (a)-[:LINKS_TO]-(b)
RETURN a.title, b.title;

// ============================================================================
// CLUSTERING & COMMUNITIES
// ============================================================================

// Documents sharing incoming links (co-citation)
MATCH (source:Document)-[:LINKS_TO]->(target1:Document),
      (source)-[:LINKS_TO]->(target2:Document)
WHERE target1 <> target2
RETURN target1.title, target2.title, COUNT(*) as shared_inlinks
ORDER BY shared_inlinks DESC;

// Documents sharing outgoing links (related topics)
MATCH (source1:Document)-[:LINKS_TO]->(target:Document),
      (source2:Document)-[:LINKS_TO]->(target:Document)
WHERE source1 <> source2
RETURN source1.title, source2.title, target.title, COUNT(*) as similarity
ORDER BY similarity DESC;

// ============================================================================
// GRAPH METRICS & STATISTICS
// ============================================================================

// Graph summary statistics
MATCH (d:Document)
WITH COUNT(d) as total_nodes,
     AVG(d.centrality) as avg_centrality,
     MAX(d.centrality) as max_centrality,
     MIN(d.centrality) as min_centrality
MATCH (a:Document)-[:LINKS_TO]->(b:Document)
WITH total_nodes, avg_centrality, max_centrality, min_centrality, 
     COUNT(*) as total_edges
RETURN {
  nodes: total_nodes,
  edges: total_edges,
  density: ROUND(toFloat(total_edges * 2) / (total_nodes * (total_nodes - 1)), 4),
  avg_centrality: ROUND(avg_centrality, 2),
  max_centrality: max_centrality,
  min_centrality: min_centrality
};

// Document distance matrix (shortest path between all pairs)
MATCH (d1:Document), (d2:Document)
WHERE d1 <> d2
WITH d1, d2,
     LENGTH(SHORTEST_PATH((d1)-[:LINKS_TO*]-(d2))) as distance
RETURN d1.title, d2.title, distance
WHERE distance > 0
ORDER BY distance ASC
LIMIT 50;

// ============================================================================
// DANGLING NODES & ORPHANS
// ============================================================================

// Documents with no incoming links (entry points)
MATCH (d:Document)
WHERE NOT (d)<-[:LINKS_TO]-()
RETURN d.title, d.centrality
ORDER BY d.centrality DESC;

// Documents with no outgoing links (leaf nodes)
MATCH (d:Document)
WHERE NOT (d)-[:LINKS_TO]->()
RETURN d.title;

// Isolated documents (no links at all)
MATCH (d:Document)
WHERE NOT (d)-[:LINKS_TO]-()
AND NOT (d)<-[:LINKS_TO]-()
RETURN d.title;

// ============================================================================
// TIME-BASED QUERIES
// ============================================================================

// Recent activity on linked documents
MATCH (d:Document)
WHERE d.updated_at > datetime() - duration('P7D')
WITH d
MATCH (d)-[:LINKS_TO]->(linked:Document)
RETURN d.title as modified, linked.title as linked_to, 
       duration.inSeconds(d.updated_at, datetime()) as age_seconds
ORDER BY age_seconds ASC;

// Documents created today
MATCH (d:Document)
WHERE date(d.created_at) = date(datetime())
RETURN d.title, d.uuid;

// ============================================================================
// SEARCH & FILTERING
// ============================================================================

// Search by tag and find related
MATCH (d:Document)
WHERE "architecture" IN d.tags
WITH d
MATCH (d)-[:LINKS_TO]->(related:Document)
RETURN d.title as tag_document, related.title as related,
       CASE WHEN "architecture" IN related.tags THEN "shared-tag" ELSE "reference" END as relationship_type;

// Find articles about multiple topics
MATCH (d:Document)
WHERE "architecture" IN d.tags
AND "performance" IN d.tags
RETURN d.title, d.tags;

// ============================================================================
// BULK OPERATIONS
// ============================================================================

// Create multiple nodes at once (Cypher batch)
UNWIND [
  {title: "New Doc 1", uuid: "550e8400-0000-0000-0000-000000000001"},
  {title: "New Doc 2", uuid: "550e8400-0000-0000-0000-000000000002"}
] as node
CREATE (d:Document {
  title: node.title,
  uuid: node.uuid,
  status: "draft",
  centrality: 0,
  inlink_count: 0,
  outlink_count: 0,
  created_at: datetime(),
  updated_at: datetime(),
  tags: []
})
RETURN COUNT(d) as created;

// Update all nodes with missing properties
MATCH (d:Document)
WHERE d.centrality IS NULL
SET d.centrality = 0
RETURN COUNT(d) as updated;

// ============================================================================
// PERFORMANCE TIPS
// ============================================================================

// Profile query (EXPLAIN)
PROFILE MATCH (d:Document {title: "API Design"})-[*1..2]-(n:Document)
RETURN DISTINCT n;

// Faster alternative: pre-computed neighborhoods
MATCH (center:Document {title: "API Design"})
RETURN [
  (neighbor)<-[:LINKS_TO]-(center) | neighbor.title
] as incoming,
[
  (center)-[:LINKS_TO]->(neighbor) | neighbor.title
] as outgoing;

// ============================================================================
// GRAPH MAINTENANCE
// ============================================================================

// Fix broken links (reference non-existent nodes)
MATCH (d1:Document)-[r:LINKS_TO]->(d2:Document)
WHERE d2 IS NULL
DELETE r;

// Recalculate all centrality measures
MATCH (d:Document)
WITH d
MATCH (d)
SET d.inlink_count = size((d)<-[:LINKS_TO]-()),
    d.outlink_count = size((d)-[:LINKS_TO]->())
RETURN COUNT(d) as updated;

// Check database integrity
MATCH ()-[r]-()
WHERE r IS NULL
RETURN COUNT(r) as orphaned_relationships;
