/**
 * Project Nexus - Governance & Access Control Module
 * Handles document workflows, user roles, and audit logging
 */

// ============================================================================
// DOCUMENT WORKFLOW STATES
// ============================================================================

export const DOCUMENT_STATUSES = {
  DRAFT: 'draft',
  REVIEW: 'review',
  PUBLISHED: 'published'
} as const

export const STATUS_TRANSITIONS: Record<string, string[]> = {
  [DOCUMENT_STATUSES.DRAFT]: [DOCUMENT_STATUSES.REVIEW, DOCUMENT_STATUSES.PUBLISHED],
  [DOCUMENT_STATUSES.REVIEW]: [DOCUMENT_STATUSES.DRAFT, DOCUMENT_STATUSES.PUBLISHED],
  [DOCUMENT_STATUSES.PUBLISHED]: [DOCUMENT_STATUSES.REVIEW, DOCUMENT_STATUSES.DRAFT]
}

// ============================================================================
// USER ROLES & PERMISSIONS
// ============================================================================

export enum UserRole {
  ADMIN = 'admin',
  USER = 'user',
  VIEWER = 'viewer'
}

export const ROLE_PERMISSIONS: Record<UserRole, string[]> = {
  [UserRole.ADMIN]: [
    'create_document',
    'edit_document',
    'delete_document',
    'publish_document',
    'manage_users',
    'view_audit_log',
    'export_graph'
  ],
  [UserRole.USER]: [
    'create_document',
    'edit_document',
    'delete_document',
    'publish_document',
    'view_audit_log'
  ],
  [UserRole.VIEWER]: [
    'view_document',
    'search_document'
  ]
}

// ============================================================================
// AUDIT LOG ENTRIES
// ============================================================================

export interface AuditLogEntry {
  id: number
  user_id: number
  action: string
  document_id: number
  old_status?: string
  new_status?: string
  timestamp: string
  details?: Record<string, any>
  ip_address?: string
}

export const AUDIT_ACTIONS = {
  CREATE_DOCUMENT: 'CREATE_DOCUMENT',
  EDIT_DOCUMENT: 'EDIT_DOCUMENT',
  DELETE_DOCUMENT: 'DELETE_DOCUMENT',
  PUBLISH_DOCUMENT: 'PUBLISH_DOCUMENT',
  CHANGE_STATUS: 'CHANGE_STATUS',
  SHARE_DOCUMENT: 'SHARE_DOCUMENT',
  ADD_TAG: 'ADD_TAG',
  REMOVE_TAG: 'REMOVE_TAG',
  CREATE_LINK: 'CREATE_LINK',
  LOGIN: 'LOGIN',
  LOGOUT: 'LOGOUT',
  MANAGE_PERMISSIONS: 'MANAGE_PERMISSIONS'
}

// ============================================================================
// DOCUMENT ACCESS CONTROL
// ============================================================================

export interface DocumentPermission {
  document_id: number
  user_id: number
  role: UserRole
  granted_at: string
  granted_by: number
}

export const CAN_PERFORM = {
  // User can edit document
  canEdit: (userRole: UserRole, docStatus: string): boolean => {
    if (userRole === UserRole.VIEWER) return false
    if (userRole === UserRole.ADMIN) return true
    // Users can edit draft/review, not published
    return [DOCUMENT_STATUSES.DRAFT, DOCUMENT_STATUSES.REVIEW].includes(docStatus)
  },

  // User can publish document
  canPublish: (userRole: UserRole): boolean => {
    return userRole !== UserRole.VIEWER
  },

  // User can delete document
  canDelete: (userRole: UserRole, docStatus: string): boolean => {
    if (userRole === UserRole.VIEWER) return false
    if (userRole === UserRole.ADMIN) return true
    // Users can only delete draft/review documents
    return [DOCUMENT_STATUSES.DRAFT, DOCUMENT_STATUSES.REVIEW].includes(docStatus)
  },

  // User can view document
  canView: (userRole: UserRole, docStatus: string): boolean => {
    if (docStatus === DOCUMENT_STATUSES.PUBLISHED) return true
    return userRole !== UserRole.VIEWER
  }
}

// ============================================================================
// WORKFLOW ENGINE
// ============================================================================

export class DocumentWorkflow {
  static canTransition(from: string, to: string): boolean {
    const allowed = STATUS_TRANSITIONS[from] || []
    return allowed.includes(to)
  }

  static getNextStates(currentStatus: string): string[] {
    return STATUS_TRANSITIONS[currentStatus] || []
  }

  static validateTransition(
    fromStatus: string,
    toStatus: string,
    userRole: UserRole
  ): { valid: boolean; error?: string } {
    // Check status transition is allowed
    if (!this.canTransition(fromStatus, toStatus)) {
      return {
        valid: false,
        error: `Cannot transition from ${fromStatus} to ${toStatus}`
      }
    }

    // Check user permission
    if (toStatus === DOCUMENT_STATUSES.PUBLISHED && !CAN_PERFORM.canPublish(userRole)) {
      return {
        valid: false,
        error: 'You do not have permission to publish documents'
      }
    }

    return { valid: true }
  }
}

// ============================================================================
// Git AUDIT LOG INTEGRATION
// ============================================================================

export interface GitCommitMessage {
  action: string
  document: {
    id: number
    title: string
    previous_status?: string
    new_status?: string
  }
  user: {
    id: number
    name: string
  }
  timestamp: string
}

export const formatGitCommitMessage = (entry: AuditLogEntry): string => {
  const timestamp = new Date(entry.timestamp).toISOString()
  
  let message = `[${entry.action}] `
  
  if (entry.old_status && entry.new_status) {
    message += `Status: ${entry.old_status} → ${entry.new_status}\n`
  }
  
  message += `Document ID: ${entry.document_id}\n`
  message += `User ID: ${entry.user_id}\n`
  message += `Time: ${timestamp}`
  
  if (entry.details) {
    message += `\n\nDetails:\n${JSON.stringify(entry.details, null, 2)}`
  }
  
  return message
}

// ============================================================================
// PERMISSION CHECKER
// ============================================================================

export class PermissionChecker {
  constructor(
    private userRole: UserRole,
    private documentStatus: string = DOCUMENT_STATUSES.DRAFT
  ) {}

  can(action: string): boolean {
    const permissions = ROLE_PERMISSIONS[this.userRole]
    return permissions.includes(action)
  }

  canEditDocument(): boolean {
    return CAN_PERFORM.canEdit(this.userRole, this.documentStatus)
  }

  canPublishDocument(): boolean {
    return CAN_PERFORM.canPublish(this.userRole)
  }

  canDeleteDocument(): boolean {
    return CAN_PERFORM.canDelete(this.userRole, this.documentStatus)
  }

  canViewDocument(): boolean {
    return CAN_PERFORM.canView(this.userRole, this.documentStatus)
  }

  getAllPermissions(): string[] {
    return ROLE_PERMISSIONS[this.userRole]
  }
}
