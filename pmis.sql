CREATE DATABASE IF NOT EXISTS pmis_db;
USE pmis_db;

-- Base tables without incoming FKs
CREATE TABLE IF NOT EXISTS Department (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Resource (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('EQUIPMENT', 'ROOM', 'LICENSE', 'MATERIAL', 'OTHER') NOT NULL,
    quantity INT NOT NULL
);

-- Tables which reference base tables
CREATE TABLE IF NOT EXISTS Employee (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES Department(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Project (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('PLANNED', 'ONGOING', 'DONE') NOT NULL,
    manager_id INT NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES Employee(id) ON DELETE RESTRICT
);

-- Tables which reference Project or others
CREATE TABLE IF NOT EXISTS Task (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    project_id INT NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('TODO', 'DOING', 'DONE') NOT NULL,
    priority ENUM('LOW', 'NORMAL', 'HIGH', 'CRITICAL') NOT NULL DEFAULT 'NORMAL',
    estimated_hours DECIMAL(5,2),
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ProjectMilestone (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    due_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ProjectRisk (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    level ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
    status VARCHAR(50) NOT NULL,  -- e.g., 'ONGOING', 'MITIGATED', 'CLOSED'
    owner_id INT,
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES Employee(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS TaskWorkLog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    work_date DATE NOT NULL,
    hours DECIMAL(5,2) NOT NULL,
    note TEXT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES Employee(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS TaskComment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    commented_at DATETIME NOT NULL,
    content TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES Employee(id) ON DELETE CASCADE
);

-- Relationship tables
CREATE TABLE IF NOT EXISTS ProjectDepartment (
    project_id INT NOT NULL,
    department_id INT NOT NULL,
    PRIMARY KEY (project_id, department_id),
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Department(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS TaskAssignment (
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (task_id, employee_id, role_id),
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES Employee(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES Role(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ResourceAllocation (
    task_id INT NOT NULL,
    resource_id INT NOT NULL,
    amount_used INT NOT NULL,
    PRIMARY KEY (task_id, resource_id),
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS TaskDependency (
    predecessor_task_id INT NOT NULL,
    successor_task_id INT NOT NULL,
    type ENUM('FS', 'SS', 'FF', 'SF') NOT NULL,
    lag_days INT,
    PRIMARY KEY (predecessor_task_id, successor_task_id),
    FOREIGN KEY (predecessor_task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (successor_task_id) REFERENCES Task(id) ON DELETE CASCADE
);

-- ============================================================================
-- 감사 로그 테이블 (Audit Log)
-- ============================================================================
CREATE TABLE IF NOT EXISTS AuditLog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    employee_id INT,
    old_value TEXT,
    new_value TEXT,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    FOREIGN KEY (employee_id) REFERENCES Employee(id) ON DELETE SET NULL,
    INDEX idx_audit_table_record (table_name, record_id),
    INDEX idx_audit_employee (employee_id),
    INDEX idx_audit_timestamp (changed_at)
);

-- Indexes for performance
CREATE INDEX idx_project_status ON Project(status);
CREATE INDEX idx_project_manager_id ON Project(manager_id);

CREATE INDEX idx_task_project_id ON Task(project_id);
CREATE INDEX idx_task_status ON Task(status);
CREATE INDEX idx_task_priority ON Task(priority);

CREATE INDEX idx_employee_department_id ON Employee(department_id);

CREATE INDEX idx_milestone_project_due ON ProjectMilestone(project_id, due_date);

CREATE INDEX idx_risk_project_id ON ProjectRisk(project_id);
CREATE INDEX idx_risk_level ON ProjectRisk(level);
CREATE INDEX idx_risk_status ON ProjectRisk(status);
CREATE INDEX idx_risk_owner_id ON ProjectRisk(owner_id);

CREATE INDEX idx_worklog_task_id ON TaskWorkLog(task_id);
CREATE INDEX idx_worklog_employee_date ON TaskWorkLog(employee_id, work_date);

CREATE INDEX idx_comment_task_id ON TaskComment(task_id);
CREATE INDEX idx_comment_employee_time ON TaskComment(employee_id, commented_at);

CREATE INDEX idx_taskdep_successor ON TaskDependency(successor_task_id);

CREATE INDEX idx_resalloc_resource_id ON ResourceAllocation(resource_id);

CREATE INDEX idx_taskassign_employee_id ON TaskAssignment(employee_id);
CREATE INDEX idx_taskassign_role_id ON TaskAssignment(role_id);

CREATE INDEX idx_projdept_department_id ON ProjectDepartment(department_id);

-- ============================================================================
-- 접근 권한 체크 함수들
-- ============================================================================

DELIMITER $$

-- Task 조회 권한 체크 함수
-- 반환값: 1 = 권한 있음, 0 = 권한 없음, -1 = 에러(NULL 또는 존재하지 않는 레코드)
CREATE FUNCTION IF NOT EXISTS check_task_read_permission(
    p_task_id INT,
    p_employee_id INT
)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE has_permission TINYINT(1) DEFAULT 0;
    DECLARE project_manager_id INT DEFAULT NULL;
    DECLARE task_exists INT DEFAULT 0;
    DECLARE employee_exists INT DEFAULT 0;
    
    -- NULL 체크
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        RETURN -1;
    END IF;
    
    -- Task 존재 여부 확인
    SELECT COUNT(*) INTO task_exists FROM Task WHERE id = p_task_id;
    IF task_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- Employee 존재 여부 확인
    SELECT COUNT(*) INTO employee_exists FROM Employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- 1. 해당 Task에 직접 배정된 직원인지 확인
    IF EXISTS (
        SELECT 1 FROM TaskAssignment 
        WHERE task_id = p_task_id AND employee_id = p_employee_id
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    -- 2. 프로젝트 관리자인지 확인
    SELECT p.manager_id INTO project_manager_id
    FROM Task t
    JOIN Project p ON t.project_id = p.id
    WHERE t.id = p_task_id;
    
    IF project_manager_id IS NOT NULL AND project_manager_id = p_employee_id THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    -- 3. 같은 부서의 부서장인지 확인 (Role 이름이 'Department Head'인 경우)
    IF EXISTS (
        SELECT 1
        FROM Task t
        JOIN Project p ON t.project_id = p.id
        JOIN ProjectDepartment pd ON p.id = pd.project_id
        JOIN Employee e ON e.department_id = pd.department_id
        JOIN TaskAssignment ta ON ta.employee_id = e.id
        JOIN Role r ON ta.role_id = r.id
        WHERE t.id = p_task_id 
        AND e.id = p_employee_id
        AND r.name = 'Department Head'
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    RETURN has_permission;
END$$

-- Task 수정 권한 체크 함수
-- 반환값: 1 = 권한 있음, 0 = 권한 없음, -1 = 에러(NULL 또는 존재하지 않는 레코드)
CREATE FUNCTION IF NOT EXISTS check_task_write_permission(
    p_task_id INT,
    p_employee_id INT
)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE has_permission TINYINT(1) DEFAULT 0;
    DECLARE project_manager_id INT DEFAULT NULL;
    DECLARE task_exists INT DEFAULT 0;
    DECLARE employee_exists INT DEFAULT 0;
    
    -- NULL 체크
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        RETURN -1;
    END IF;
    
    -- Task 존재 여부 확인
    SELECT COUNT(*) INTO task_exists FROM Task WHERE id = p_task_id;
    IF task_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- Employee 존재 여부 확인
    SELECT COUNT(*) INTO employee_exists FROM Employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- 1. 해당 Task에 쓰기 권한이 있는 Role로 배정된 직원인지 확인
    IF EXISTS (
        SELECT 1 FROM TaskAssignment ta
        JOIN Role r ON ta.role_id = r.id
        WHERE ta.task_id = p_task_id 
        AND ta.employee_id = p_employee_id
        AND r.name IN ('Developer', 'Lead', 'Assignee')  -- 쓰기 권한이 있는 Role들
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    -- 2. 프로젝트 관리자인지 확인
    SELECT p.manager_id INTO project_manager_id
    FROM Task t
    JOIN Project p ON t.project_id = p.id
    WHERE t.id = p_task_id;
    
    IF project_manager_id IS NOT NULL AND project_manager_id = p_employee_id THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    RETURN has_permission;
END$$

DELIMITER ;

-- ============================================================================
-- 감사 로그 자동 생성 트리거들
-- ============================================================================

DELIMITER $$

-- Task INSERT 트리거
CREATE TRIGGER IF NOT EXISTS task_after_insert
AFTER INSERT ON Task
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action, new_value)
    VALUES (
        'Task',
        NEW.id,
        'INSERT',
        CONCAT('name=', IFNULL(NEW.name, 'NULL'), 
               ', status=', IFNULL(NEW.status, 'NULL'), 
               ', priority=', IFNULL(NEW.priority, 'NULL'))
    );
END$$

-- Task UPDATE 트리거
CREATE TRIGGER IF NOT EXISTS task_after_update
AFTER UPDATE ON Task
FOR EACH ROW
BEGIN
    DECLARE changes TEXT DEFAULT '';
    
    -- NULL-safe 비교
    IF (OLD.name IS NULL AND NEW.name IS NOT NULL) OR 
       (OLD.name IS NOT NULL AND NEW.name IS NULL) OR 
       (OLD.name IS NOT NULL AND NEW.name IS NOT NULL AND OLD.name != NEW.name) THEN
        SET changes = CONCAT(changes, 'name: ', IFNULL(OLD.name, 'NULL'), ' -> ', IFNULL(NEW.name, 'NULL'), '; ');
    END IF;
    
    IF (OLD.status IS NULL AND NEW.status IS NOT NULL) OR 
       (OLD.status IS NOT NULL AND NEW.status IS NULL) OR 
       (OLD.status IS NOT NULL AND NEW.status IS NOT NULL AND OLD.status != NEW.status) THEN
        SET changes = CONCAT(changes, 'status: ', IFNULL(OLD.status, 'NULL'), ' -> ', IFNULL(NEW.status, 'NULL'), '; ');
    END IF;
    
    IF (OLD.priority IS NULL AND NEW.priority IS NOT NULL) OR 
       (OLD.priority IS NOT NULL AND NEW.priority IS NULL) OR 
       (OLD.priority IS NOT NULL AND NEW.priority IS NOT NULL AND OLD.priority != NEW.priority) THEN
        SET changes = CONCAT(changes, 'priority: ', IFNULL(OLD.priority, 'NULL'), ' -> ', IFNULL(NEW.priority, 'NULL'), '; ');
    END IF;
    
    IF (OLD.start_date IS NULL AND NEW.start_date IS NOT NULL) OR 
       (OLD.start_date IS NOT NULL AND NEW.start_date IS NULL) OR 
       (OLD.start_date IS NOT NULL AND NEW.start_date IS NOT NULL AND OLD.start_date != NEW.start_date) THEN
        SET changes = CONCAT(changes, 'start_date: ', IFNULL(OLD.start_date, 'NULL'), ' -> ', IFNULL(NEW.start_date, 'NULL'), '; ');
    END IF;
    
    IF (OLD.end_date IS NULL AND NEW.end_date IS NOT NULL) OR 
       (OLD.end_date IS NOT NULL AND NEW.end_date IS NULL) OR 
       (OLD.end_date IS NOT NULL AND NEW.end_date IS NOT NULL AND OLD.end_date != NEW.end_date) THEN
        SET changes = CONCAT(changes, 'end_date: ', IFNULL(OLD.end_date, 'NULL'), ' -> ', IFNULL(NEW.end_date, 'NULL'), '; ');
    END IF;
    
    IF changes != '' THEN
        INSERT INTO AuditLog (table_name, record_id, action, old_value, new_value)
        VALUES (
            'Task',
            NEW.id,
            'UPDATE',
            CONCAT('name=', IFNULL(OLD.name, 'NULL'), 
                   ', status=', IFNULL(OLD.status, 'NULL'), 
                   ', priority=', IFNULL(OLD.priority, 'NULL')),
            changes
        );
    END IF;
END$$

-- Task DELETE 트리거
CREATE TRIGGER IF NOT EXISTS task_after_delete
AFTER DELETE ON Task
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action, old_value)
    VALUES (
        'Task',
        OLD.id,
        'DELETE',
        CONCAT('name=', IFNULL(OLD.name, 'NULL'), 
               ', status=', IFNULL(OLD.status, 'NULL'), 
               ', priority=', IFNULL(OLD.priority, 'NULL'))
    );
END$$

-- TaskAssignment INSERT 트리거 (권한 부여 감사)
CREATE TRIGGER IF NOT EXISTS task_assignment_after_insert
AFTER INSERT ON TaskAssignment
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action, employee_id, new_value)
    VALUES (
        'TaskAssignment',
        NEW.task_id,
        'INSERT',
        NEW.employee_id,
        CONCAT('task_id=', IFNULL(NEW.task_id, 'NULL'), 
               ', employee_id=', IFNULL(NEW.employee_id, 'NULL'), 
               ', role_id=', IFNULL(NEW.role_id, 'NULL'))
    );
END$$

-- TaskAssignment DELETE 트리거 (권한 제거 감사)
CREATE TRIGGER IF NOT EXISTS task_assignment_after_delete
AFTER DELETE ON TaskAssignment
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action, employee_id, old_value)
    VALUES (
        'TaskAssignment',
        OLD.task_id,
        'DELETE',
        OLD.employee_id,
        CONCAT('task_id=', IFNULL(OLD.task_id, 'NULL'), 
               ', employee_id=', IFNULL(OLD.employee_id, 'NULL'), 
               ', role_id=', IFNULL(OLD.role_id, 'NULL'))
    );
END$$

DELIMITER ;

-- ============================================================================
-- 권한 기반 조회 VIEW
-- ============================================================================

-- 직원이 접근 가능한 Task 목록 VIEW
-- 사용법: SELECT * FROM accessible_tasks WHERE employee_id = ?
CREATE OR REPLACE VIEW accessible_tasks AS
SELECT DISTINCT
    t.*,
    ta.employee_id as accessor_employee_id,
    CASE
        WHEN p.manager_id = ta.employee_id THEN 'PROJECT_MANAGER'
        WHEN ta.employee_id IS NOT NULL THEN 'ASSIGNED'
        ELSE 'NONE'
    END as access_level
FROM Task t
JOIN Project p ON t.project_id = p.id
LEFT JOIN TaskAssignment ta ON t.id = ta.task_id
WHERE ta.employee_id IS NOT NULL OR p.manager_id = ta.employee_id;

-- ============================================================================
-- 권한 체크를 위한 Stored Procedures
-- ============================================================================

DELIMITER $$

-- Task 조회 프로시저 (권한 체크 포함)
CREATE PROCEDURE IF NOT EXISTS get_task_with_permission(
    IN p_task_id INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE has_read_permission TINYINT(1);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as access_status, 'Database error occurred' as message;
        ROLLBACK;
    END;
    
    -- NULL 체크
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        SELECT NULL as id, 'INVALID_INPUT' as access_status, 'Task ID and Employee ID cannot be NULL' as message;
    ELSE
        SET has_read_permission = check_task_read_permission(p_task_id, p_employee_id);
        
        IF has_read_permission = -1 THEN
            SELECT NULL as id, 'NOT_FOUND' as access_status, 'Task or Employee not found' as message;
        ELSEIF has_read_permission = 1 THEN
            SELECT t.*, 'GRANTED' as access_status, 'Access granted' as message
            FROM Task t
            WHERE t.id = p_task_id;
        ELSE
            SELECT NULL as id, 'ACCESS_DENIED' as access_status, 'You do not have permission to view this task' as message;
        END IF;
    END IF;
END$$

-- Task 수정 프로시저 (권한 체크 포함)
CREATE PROCEDURE IF NOT EXISTS update_task_with_permission(
    IN p_task_id INT,
    IN p_employee_id INT,
    IN p_new_name VARCHAR(255),
    IN p_new_status VARCHAR(20),
    IN p_new_priority VARCHAR(20)
)
BEGIN
    DECLARE has_write_permission TINYINT(1);
    DECLARE valid_status TINYINT(1) DEFAULT 1;
    DECLARE valid_priority TINYINT(1) DEFAULT 1;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during update' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- NULL 체크
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Task ID and Employee ID cannot be NULL' as message;
        ROLLBACK;
    ELSE
        -- Status 유효성 검사
        IF p_new_status IS NOT NULL AND p_new_status NOT IN ('TODO', 'DOING', 'DONE') THEN
            SET valid_status = 0;
        END IF;
        
        -- Priority 유효성 검사
        IF p_new_priority IS NOT NULL AND p_new_priority NOT IN ('LOW', 'NORMAL', 'HIGH', 'CRITICAL') THEN
            SET valid_priority = 0;
        END IF;
        
        IF valid_status = 0 OR valid_priority = 0 THEN
            SELECT 'INVALID_INPUT' as result, 
                   CONCAT('Invalid ', 
                          IF(valid_status = 0, 'status', ''),
                          IF(valid_status = 0 AND valid_priority = 0, ' and ', ''),
                          IF(valid_priority = 0, 'priority', '')) as message;
            ROLLBACK;
        ELSE
            SET has_write_permission = check_task_write_permission(p_task_id, p_employee_id);
            
            IF has_write_permission = -1 THEN
                SELECT 'NOT_FOUND' as result, 'Task or Employee not found' as message;
                ROLLBACK;
            ELSEIF has_write_permission = 1 THEN
                UPDATE Task
                SET 
                    name = IFNULL(p_new_name, name),
                    status = IFNULL(p_new_status, status),
                    priority = IFNULL(p_new_priority, priority)
                WHERE id = p_task_id;
                
                SELECT 'SUCCESS' as result, 'Task updated successfully' as message, ROW_COUNT() as rows_affected;
                COMMIT;
            ELSE
                SELECT 'ACCESS_DENIED' as result, 'You do not have permission to update this task' as message;
                ROLLBACK;
            END IF;
        END IF;
    END IF;
END$$

-- 직원이 접근 가능한 모든 Task 조회 프로시저
CREATE PROCEDURE IF NOT EXISTS get_employee_accessible_tasks(
    IN p_employee_id INT
)
BEGIN
    DECLARE employee_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred' as message;
    END;
    
    -- NULL 체크
    IF p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Employee ID cannot be NULL' as message;
    ELSE
        -- Employee 존재 여부 확인
        SELECT COUNT(*) INTO employee_exists FROM Employee WHERE id = p_employee_id;
        
        IF employee_exists = 0 THEN
            SELECT 'NOT_FOUND' as result, 'Employee not found' as message;
        ELSE
            SELECT t.*,
                   CASE
                       WHEN p.manager_id = p_employee_id THEN 'PROJECT_MANAGER'
                       WHEN ta.employee_id IS NOT NULL THEN 'ASSIGNED'
                       ELSE 'NONE'
                   END as access_level,
                   r.name as role_name,
                   p.name as project_name
            FROM Task t
            JOIN Project p ON t.project_id = p.id
            LEFT JOIN TaskAssignment ta ON t.id = ta.task_id AND ta.employee_id = p_employee_id
            LEFT JOIN Role r ON ta.role_id = r.id
            WHERE p.manager_id = p_employee_id OR ta.employee_id IS NOT NULL
            ORDER BY t.project_id, t.priority DESC, t.id;
        END IF;
    END IF;
END$$

-- 감사 로그 조회 프로시저
CREATE PROCEDURE IF NOT EXISTS get_audit_log(
    IN p_table_name VARCHAR(50),
    IN p_record_id INT,
    IN p_limit INT
)
BEGIN
    DECLARE safe_limit INT DEFAULT 100;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred' as message;
    END;
    
    -- Limit 유효성 검사 (최대 1000)
    IF p_limit IS NOT NULL THEN
        IF p_limit <= 0 THEN
            SET safe_limit = 100;
        ELSEIF p_limit > 1000 THEN
            SET safe_limit = 1000;
        ELSE
            SET safe_limit = p_limit;
        END IF;
    END IF;
    
    IF p_table_name IS NOT NULL AND p_record_id IS NOT NULL THEN
        -- 특정 테이블의 특정 레코드
        SELECT a.*, e.name as employee_name
        FROM AuditLog a
        LEFT JOIN Employee e ON a.employee_id = e.id
        WHERE a.table_name = p_table_name AND a.record_id = p_record_id
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    ELSEIF p_table_name IS NOT NULL THEN
        -- 특정 테이블의 모든 레코드
        SELECT a.*, e.name as employee_name
        FROM AuditLog a
        LEFT JOIN Employee e ON a.employee_id = e.id
        WHERE a.table_name = p_table_name
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    ELSE
        -- 모든 감사 로그
        SELECT a.*, e.name as employee_name
        FROM AuditLog a
        LEFT JOIN Employee e ON a.employee_id = e.id
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    END IF;
END$$

-- Task 삭제 프로시저 (권한 체크 포함)
CREATE PROCEDURE IF NOT EXISTS delete_task_with_permission(
    IN p_task_id INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE has_write_permission TINYINT(1);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during delete' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- NULL 체크
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Task ID and Employee ID cannot be NULL' as message;
        ROLLBACK;
    ELSE
        SET has_write_permission = check_task_write_permission(p_task_id, p_employee_id);
        
        IF has_write_permission = -1 THEN
            SELECT 'NOT_FOUND' as result, 'Task or Employee not found' as message;
            ROLLBACK;
        ELSEIF has_write_permission = 1 THEN
            DELETE FROM Task WHERE id = p_task_id;
            SELECT 'SUCCESS' as result, 'Task deleted successfully' as message, ROW_COUNT() as rows_affected;
            COMMIT;
        ELSE
            SELECT 'ACCESS_DENIED' as result, 'You do not have permission to delete this task' as message;
            ROLLBACK;
        END IF;
    END IF;
END$$

DELIMITER ;