CREATE DATABASE IF NOT EXISTS pmis_db;
USE pmis_db;

-- Base tables
CREATE TABLE IF NOT EXISTS department (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS resource (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('EQUIPMENT', 'ROOM', 'LICENSE', 'MATERIAL', 'OTHER') NOT NULL,
    quantity INT NOT NULL
);

-- Tables which reference base tables
CREATE TABLE IF NOT EXISTS employee (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS project (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('PLANNED', 'ONGOING', 'DONE') NOT NULL,
    manager_id INT NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES employee(id) ON DELETE RESTRICT
);

-- Tables which reference Project or others
CREATE TABLE IF NOT EXISTS task (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    project_id INT NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('TODO', 'DOING', 'DONE') NOT NULL,
    priority ENUM('LOW', 'NORMAL', 'HIGH', 'CRITICAL') NOT NULL DEFAULT 'NORMAL',
    estimated_hours DECIMAL(5,2),
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS project_milestone (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    due_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS project_risk (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    level ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
    status VARCHAR(50) NOT NULL,  -- 'ONGOING', 'MITIGATED', 'CLOSED'
    owner_id INT,
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES employee(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS task_work_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    work_date DATE NOT NULL,
    hours DECIMAL(5,2) NOT NULL,
    note TEXT,
    FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS task_comment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    commented_at DATETIME NOT NULL,
    content TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE
);

-- Relationship tables
CREATE TABLE IF NOT EXISTS project_department (
    project_id INT NOT NULL,
    department_id INT NOT NULL,
    PRIMARY KEY (project_id, department_id),
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS task_assignment (
    task_id INT NOT NULL,
    employee_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (task_id, employee_id, role_id),
    FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS resource_allocation (
    task_id INT NOT NULL,
    resource_id INT NOT NULL,
    amount_used INT NOT NULL,
    PRIMARY KEY (task_id, resource_id),
    FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resource(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS task_dependency (
    predecessor_task_id INT NOT NULL,
    successor_task_id INT NOT NULL,
    type ENUM('FS', 'SS', 'FF', 'SF') NOT NULL,
    lag_days INT,
    PRIMARY KEY (predecessor_task_id, successor_task_id),
    FOREIGN KEY (predecessor_task_id) REFERENCES task(id) ON DELETE CASCADE,
    FOREIGN KEY (successor_task_id) REFERENCES task(id) ON DELETE CASCADE
);

-- 감사 로그 테이블 (Audit Log)
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    employee_id INT,
    old_value TEXT,
    new_value TEXT,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE SET NULL,
    INDEX idx_audit_table_record (table_name, record_id),
    INDEX idx_audit_employee (employee_id),
    INDEX idx_audit_timestamp (changed_at)
);

-- Indexes
CREATE INDEX idx_project_status ON project(status);
CREATE INDEX idx_project_manager_id ON project(manager_id);

CREATE INDEX idx_task_project_id ON task(project_id);
CREATE INDEX idx_task_status ON task(status);
CREATE INDEX idx_task_priority ON task(priority);

CREATE INDEX idx_employee_department_id ON employee(department_id);

CREATE INDEX idx_milestone_project_due ON project_milestone(project_id, due_date);

CREATE INDEX idx_risk_project_id ON project_risk(project_id);
CREATE INDEX idx_risk_level ON project_risk(level);
CREATE INDEX idx_risk_status ON project_risk(status);
CREATE INDEX idx_risk_owner_id ON project_risk(owner_id);

CREATE INDEX idx_worklog_task_id ON task_work_log(task_id);
CREATE INDEX idx_worklog_employee_date ON task_work_log(employee_id, work_date);

CREATE INDEX idx_comment_task_id ON task_comment(task_id);
CREATE INDEX idx_comment_employee_time ON task_comment(employee_id, commented_at);

CREATE INDEX idx_taskdep_successor ON task_dependency(successor_task_id);

CREATE INDEX idx_resalloc_resource_id ON resource_allocation(resource_id);

CREATE INDEX idx_taskassign_employee_id ON task_assignment(employee_id);
CREATE INDEX idx_taskassign_role_id ON task_assignment(role_id);

CREATE INDEX idx_projdept_department_id ON project_department(department_id);

-- 접근 권한 체크 함수

DELIMITER $$

-- Task 조회 권한 체크 함수
-- 반환값: 1 = 권한 있음, 0 = 권한 없음, -1 = 에러
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
    SELECT COUNT(*) INTO task_exists FROM task WHERE id = p_task_id;
    IF task_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- Employee 존재 여부 확인
    SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- 1. 해당 Task에 직접 배정된 직원인지 확인
    IF EXISTS (
        SELECT 1 FROM task_assignment 
        WHERE task_id = p_task_id AND employee_id = p_employee_id
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    -- 2. 프로젝트 관리자인지 확인
    SELECT p.manager_id INTO project_manager_id
    FROM task t
    JOIN project p ON t.project_id = p.id
    WHERE t.id = p_task_id;
    
    IF project_manager_id IS NOT NULL AND project_manager_id = p_employee_id THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    -- 3. 같은 부서의 부서장인지 확인 (Role 이름이 'Department Head'인 경우)
    IF EXISTS (
        SELECT 1
        FROM task t
        JOIN project p ON t.project_id = p.id
        JOIN project_department pd ON p.id = pd.project_id
        JOIN employee e ON e.department_id = pd.department_id
        JOIN task_assignment ta ON ta.employee_id = e.id
        JOIN role r ON ta.role_id = r.id
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
-- 반환값: 1 = 권한 있음, 0 = 권한 없음, -1 = 에러
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
    SELECT COUNT(*) INTO task_exists FROM task WHERE id = p_task_id;
    IF task_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- Employee 존재 여부 확인
    SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- 1. 해당 Task에 쓰기 권한이 있는 Role로 배정된 직원인지 확인
    IF EXISTS (
        SELECT 1 FROM task_assignment ta
        JOIN role r ON ta.role_id = r.id
        WHERE ta.task_id = p_task_id 
        AND ta.employee_id = p_employee_id
        AND r.name IN ('Developer', 'Lead', 'Assignee')
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    -- 2. 프로젝트 관리자인지 확인
    SELECT p.manager_id INTO project_manager_id
    FROM task t
    JOIN project p ON t.project_id = p.id
    WHERE t.id = p_task_id;
    
    IF project_manager_id IS NOT NULL AND project_manager_id = p_employee_id THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
    RETURN has_permission;
END$$

-- Project 수정 권한 체크 함수 (프로젝트 매니저만 허용)
-- 반환값: 1 = 권한 있음, 0 = 권한 없음, -1 = 에러/존재하지 않음
CREATE FUNCTION IF NOT EXISTS check_project_write_permission(
    p_project_id INT,
    p_employee_id INT
)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE has_permission TINYINT(1) DEFAULT 0;
    DECLARE project_exists INT DEFAULT 0;
    DECLARE employee_exists INT DEFAULT 0;
    DECLARE manager_id INT DEFAULT NULL;
    
    -- NULL 체크
    IF p_project_id IS NULL OR p_employee_id IS NULL THEN
        RETURN -1;
    END IF;
    
    -- Project 존재 여부 확인
    SELECT COUNT(*) INTO project_exists FROM project WHERE id = p_project_id;
    IF project_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- Employee 존재 여부 확인
    SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    -- 프로젝트 매니저인지 확인
    SELECT manager_id INTO manager_id FROM project WHERE id = p_project_id;
    IF manager_id IS NOT NULL AND manager_id = p_employee_id THEN
        SET has_permission = 1;
    END IF;
    
    RETURN has_permission;
END$$

-- Milestone/Task/Risk 등 프로젝트 하위 리소스 수정 시 PM 여부 확인
-- 반환값: 1 = 권한 있음(프로젝트 매니저), 0 = 권한 없음, -1 = 에러/존재하지 않음
CREATE FUNCTION IF NOT EXISTS check_project_child_write_permission(
    p_project_id INT,
    p_employee_id INT
)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE has_permission TINYINT(1) DEFAULT 0;
    DECLARE project_exists INT DEFAULT 0;
    DECLARE employee_exists INT DEFAULT 0;
    DECLARE manager_id INT DEFAULT NULL;
    
    IF p_project_id IS NULL OR p_employee_id IS NULL THEN
        RETURN -1;
    END IF;
    
    SELECT COUNT(*) INTO project_exists FROM project WHERE id = p_project_id;
    IF project_exists = 0 THEN
        RETURN -1;
    END IF;
    
    SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    SELECT manager_id INTO manager_id FROM project WHERE id = p_project_id;
    IF manager_id IS NOT NULL AND manager_id = p_employee_id THEN
        SET has_permission = 1;
    END IF;
    
    RETURN has_permission;
END$$

DELIMITER ;

-- 감사 로그 자동 생성 트리거

DELIMITER $$

-- Task INSERT 트리거
CREATE TRIGGER IF NOT EXISTS task_after_insert
AFTER INSERT ON task
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, new_value)
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
AFTER UPDATE ON task
FOR EACH ROW
BEGIN
    DECLARE changes TEXT DEFAULT '';
    
    -- NULL safe
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
        INSERT INTO audit_log (table_name, record_id, action, old_value, new_value)
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
AFTER DELETE ON task
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, old_value)
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
AFTER INSERT ON task_assignment
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, employee_id, new_value)
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
AFTER DELETE ON task_assignment
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, employee_id, old_value)
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

-- 권한 기반 조회 VIEW

-- 직원이 접근 가능한 Task 목록 VIEW
CREATE OR REPLACE VIEW accessible_tasks AS
SELECT DISTINCT
    t.*,
    ta.employee_id as accessor_employee_id,
    CASE
        WHEN p.manager_id = ta.employee_id THEN 'PROJECT_MANAGER'
        WHEN ta.employee_id IS NOT NULL THEN 'ASSIGNED'
        ELSE 'NONE'
    END as access_level
FROM task t
JOIN project p ON t.project_id = p.id
LEFT JOIN task_assignment ta ON t.id = ta.task_id
WHERE ta.employee_id IS NOT NULL OR p.manager_id = ta.employee_id;

-- 권한 체크를 위한 Stored Procedures

DELIMITER $$

-- Project 수정 프로시저 (프로젝트 매니저만 수정 가능)
CREATE PROCEDURE IF NOT EXISTS update_project_with_permission(
    IN p_project_id INT,
    IN p_employee_id INT,
    IN p_new_name VARCHAR(255),
    IN p_new_status VARCHAR(20),
    IN p_new_start_date DATE,
    IN p_new_end_date DATE
)
BEGIN
    DECLARE has_write_permission TINYINT(1);
    DECLARE valid_status TINYINT(1) DEFAULT 1;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during project update' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- NULL 체크
    IF p_project_id IS NULL OR p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Project ID and Employee ID cannot be NULL' as message;
        ROLLBACK;
    ELSE
        -- Status 유효성 검사
        IF p_new_status IS NOT NULL AND p_new_status NOT IN ('PLANNED', 'ONGOING', 'DONE') THEN
            SET valid_status = 0;
        END IF;
        
        IF valid_status = 0 THEN
            SELECT 'INVALID_INPUT' as result, 'Invalid project status' as message;
            ROLLBACK;
        ELSE
            SET has_write_permission = check_project_write_permission(p_project_id, p_employee_id);
            
            IF has_write_permission = -1 THEN
                SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
                ROLLBACK;
            ELSEIF has_write_permission = 1 THEN
                UPDATE project
                SET
                    name = IFNULL(p_new_name, name),
                    status = IFNULL(p_new_status, status),
                    start_date = IFNULL(p_new_start_date, start_date),
                    end_date = IFNULL(p_new_end_date, end_date)
                WHERE id = p_project_id;
                
                SELECT 'SUCCESS' as result, 'Project updated successfully' as message, ROW_COUNT() as rows_affected;
                COMMIT;
            ELSE
                SELECT 'ACCESS_DENIED' as result, 'You do not have permission to update this project (manager only)' as message;
                ROLLBACK;
            END IF;
        END IF;
    END IF;
END$$

-- Milestone 생성/완료 (프로젝트 매니저만 허용)
CREATE PROCEDURE IF NOT EXISTS create_milestone_with_permission(
    IN p_project_id INT,
    IN p_employee_id INT,
    IN p_name VARCHAR(255),
    IN p_due_date DATE
)
BEGIN
    DECLARE has_permission TINYINT(1);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during milestone creation' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    SET has_permission = check_project_child_write_permission(p_project_id, p_employee_id);
    IF has_permission = -1 THEN
        SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
        ROLLBACK;
    ELSEIF has_permission = 0 THEN
        SELECT 'ACCESS_DENIED' as result, 'Only the project manager can create milestones' as message;
        ROLLBACK;
    ELSE
        INSERT INTO project_milestone (project_id, name, due_date, is_completed)
        VALUES (p_project_id, p_name, p_due_date, FALSE);
        SELECT 'SUCCESS' as result, 'Milestone created' as message, LAST_INSERT_ID() as milestone_id;
        COMMIT;
    END IF;
END$$

CREATE PROCEDURE IF NOT EXISTS complete_milestone_with_permission(
    IN p_project_id INT,
    IN p_milestone_id INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE has_permission TINYINT(1);
    DECLARE milestone_project_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during milestone completion' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    SET has_permission = check_project_child_write_permission(p_project_id, p_employee_id);
    IF has_permission = -1 THEN
        SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
        ROLLBACK;
    ELSEIF has_permission = 0 THEN
        SELECT 'ACCESS_DENIED' as result, 'Only the project manager can complete milestones' as message;
        ROLLBACK;
    ELSE
        SELECT project_id INTO milestone_project_id FROM project_milestone WHERE id = p_milestone_id;
        IF milestone_project_id IS NULL THEN
            SELECT 'NOT_FOUND' as result, 'Milestone not found' as message;
            ROLLBACK;
        ELSEIF milestone_project_id != p_project_id THEN
            SELECT 'INVALID_INPUT' as result, 'Milestone does not belong to the specified project' as message;
            ROLLBACK;
        ELSE
            UPDATE project_milestone SET is_completed = TRUE WHERE id = p_milestone_id;
            SELECT 'SUCCESS' as result, 'Milestone completed' as message, ROW_COUNT() as rows_affected;
            COMMIT;
        END IF;
    END IF;
END$$

-- Risk 생성/상태 변경 (프로젝트 매니저만 허용)
CREATE PROCEDURE IF NOT EXISTS create_risk_with_permission(
    IN p_project_id INT,
    IN p_employee_id INT,
    IN p_owner_id INT,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_level ENUM('LOW','MEDIUM','HIGH','CRITICAL')
)
BEGIN
    DECLARE has_permission TINYINT(1);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during risk creation' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    SET has_permission = check_project_child_write_permission(p_project_id, p_employee_id);
    IF has_permission = -1 THEN
        SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
        ROLLBACK;
    ELSEIF has_permission = 0 THEN
        SELECT 'ACCESS_DENIED' as result, 'Only the project manager can create risks' as message;
        ROLLBACK;
    ELSE
        INSERT INTO project_risk (project_id, owner_id, title, description, level, status, created_at)
        VALUES (p_project_id, p_owner_id, p_title, p_description, p_level, 'OPEN', NOW());
        SELECT 'SUCCESS' as result, 'Risk created' as message, LAST_INSERT_ID() as risk_id;
        COMMIT;
    END IF;
END$$

CREATE PROCEDURE IF NOT EXISTS update_risk_status_with_permission(
    IN p_project_id INT,
    IN p_risk_id INT,
    IN p_status VARCHAR(50),
    IN p_employee_id INT
)
BEGIN
    DECLARE has_permission TINYINT(1);
    DECLARE risk_project_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during risk status update' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    SET has_permission = check_project_child_write_permission(p_project_id, p_employee_id);
    IF has_permission = -1 THEN
        SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
        ROLLBACK;
    ELSEIF has_permission = 0 THEN
        SELECT 'ACCESS_DENIED' as result, 'Only the project manager can update risks' as message;
        ROLLBACK;
    ELSE
        SELECT project_id INTO risk_project_id FROM project_risk WHERE id = p_risk_id;
        IF risk_project_id IS NULL THEN
            SELECT 'NOT_FOUND' as result, 'Risk not found' as message;
            ROLLBACK;
        ELSEIF risk_project_id != p_project_id THEN
            SELECT 'INVALID_INPUT' as result, 'Risk does not belong to the specified project' as message;
            ROLLBACK;
        ELSE
            UPDATE project_risk SET status = p_status, updated_at = NOW() WHERE id = p_risk_id;
            SELECT 'SUCCESS' as result, 'Risk status updated' as message, ROW_COUNT() as rows_affected;
            COMMIT;
        END IF;
    END IF;
END$$

-- Task Dependency 생성/삭제 (프로젝트 매니저만 허용)
CREATE PROCEDURE IF NOT EXISTS create_task_dependency_with_permission(
    IN p_predecessor_task_id INT,
    IN p_successor_task_id INT,
    IN p_type ENUM('FS','SS','FF','SF'),
    IN p_lag_days INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE has_permission TINYINT(1);
    DECLARE pre_project_id INT;
    DECLARE suc_project_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during dependency creation' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    SELECT project_id INTO pre_project_id FROM task WHERE id = p_predecessor_task_id;
    SELECT project_id INTO suc_project_id FROM task WHERE id = p_successor_task_id;
    
    IF pre_project_id IS NULL OR suc_project_id IS NULL THEN
        SELECT 'NOT_FOUND' as result, 'Predecessor or Successor task not found' as message;
        ROLLBACK;
    ELSEIF pre_project_id != suc_project_id THEN
        SELECT 'INVALID_INPUT' as result, 'Tasks must belong to the same project' as message;
        ROLLBACK;
    ELSE
        SET has_permission = check_project_child_write_permission(pre_project_id, p_employee_id);
        IF has_permission = -1 THEN
            SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
            ROLLBACK;
        ELSEIF has_permission = 0 THEN
            SELECT 'ACCESS_DENIED' as result, 'Only the project manager can create task dependencies' as message;
            ROLLBACK;
        ELSE
            INSERT INTO task_dependency (predecessor_task_id, successor_task_id, type, lag_days)
            VALUES (p_predecessor_task_id, p_successor_task_id, p_type, p_lag_days);
            SELECT 'SUCCESS' as result, 'Task dependency created' as message;
            COMMIT;
        END IF;
    END IF;
END$$

CREATE PROCEDURE IF NOT EXISTS delete_task_dependency_with_permission(
    IN p_predecessor_task_id INT,
    IN p_successor_task_id INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE has_permission TINYINT(1);
    DECLARE pre_project_id INT;
    DECLARE suc_project_id INT;
    DECLARE dep_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during dependency delete' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    SELECT project_id INTO pre_project_id FROM task WHERE id = p_predecessor_task_id;
    SELECT project_id INTO suc_project_id FROM task WHERE id = p_successor_task_id;
    SELECT COUNT(*) INTO dep_exists FROM task_dependency
        WHERE predecessor_task_id = p_predecessor_task_id AND successor_task_id = p_successor_task_id;
    
    IF pre_project_id IS NULL OR suc_project_id IS NULL THEN
        SELECT 'NOT_FOUND' as result, 'Predecessor or Successor task not found' as message;
        ROLLBACK;
    ELSEIF pre_project_id != suc_project_id THEN
        SELECT 'INVALID_INPUT' as result, 'Tasks must belong to the same project' as message;
        ROLLBACK;
    ELSEIF dep_exists = 0 THEN
        SELECT 'NOT_FOUND' as result, 'Task dependency not found' as message;
        ROLLBACK;
    ELSE
        SET has_permission = check_project_child_write_permission(pre_project_id, p_employee_id);
        IF has_permission = -1 THEN
            SELECT 'NOT_FOUND' as result, 'Project or Employee not found' as message;
            ROLLBACK;
        ELSEIF has_permission = 0 THEN
            SELECT 'ACCESS_DENIED' as result, 'Only the project manager can delete task dependencies' as message;
            ROLLBACK;
        ELSE
            DELETE FROM task_dependency
            WHERE predecessor_task_id = p_predecessor_task_id
              AND successor_task_id = p_successor_task_id;
            SELECT 'SUCCESS' as result, 'Task dependency deleted' as message, ROW_COUNT() as rows_affected;
            COMMIT;
        END IF;
    END IF;
END$$

-- Task Assignment 추가/삭제 (프로젝트 매니저만 허용)
CREATE PROCEDURE IF NOT EXISTS create_task_assignment_with_permission(
    IN p_task_id INT,
    IN p_employee_id_to_assign INT,
    IN p_role_id INT,
    IN p_employee_id_requester INT
)
BEGIN
    DECLARE task_project_id INT;
    DECLARE has_permission TINYINT(1);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during task assignment creation' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    SELECT project_id INTO task_project_id FROM task WHERE id = p_task_id;
    IF task_project_id IS NULL THEN
        SELECT 'NOT_FOUND' as result, 'Task not found' as message;
        ROLLBACK;
    ELSE
        SET has_permission = check_project_child_write_permission(task_project_id, p_employee_id_requester);
        IF has_permission = -1 THEN
            SELECT 'NOT_FOUND' as result, 'Project or Employee (requester) not found' as message;
            ROLLBACK;
        ELSEIF has_permission = 0 THEN
            SELECT 'ACCESS_DENIED' as result, 'Only the project manager can assign tasks' as message;
            ROLLBACK;
        ELSE
            INSERT INTO task_assignment (task_id, employee_id, role_id)
            VALUES (p_task_id, p_employee_id_to_assign, p_role_id);
            SELECT 'SUCCESS' as result, 'Task assignment created' as message;
            COMMIT;
        END IF;
    END IF;
END$$

CREATE PROCEDURE IF NOT EXISTS delete_task_assignment_with_permission(
    IN p_task_id INT,
    IN p_employee_id_to_remove INT,
    IN p_role_id INT,
    IN p_employee_id_requester INT
)
BEGIN
    DECLARE task_project_id INT;
    DECLARE has_permission TINYINT(1);
    DECLARE assignment_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred during task assignment delete' as message;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    SELECT project_id INTO task_project_id FROM task WHERE id = p_task_id;
    SELECT COUNT(*) INTO assignment_exists FROM task_assignment
        WHERE task_id = p_task_id AND employee_id = p_employee_id_to_remove AND role_id = p_role_id;
    
    IF task_project_id IS NULL THEN
        SELECT 'NOT_FOUND' as result, 'Task not found' as message;
        ROLLBACK;
    ELSEIF assignment_exists = 0 THEN
        SELECT 'NOT_FOUND' as result, 'Task assignment not found' as message;
        ROLLBACK;
    ELSE
        SET has_permission = check_project_child_write_permission(task_project_id, p_employee_id_requester);
        IF has_permission = -1 THEN
            SELECT 'NOT_FOUND' as result, 'Project or Employee (requester) not found' as message;
            ROLLBACK;
        ELSEIF has_permission = 0 THEN
            SELECT 'ACCESS_DENIED' as result, 'Only the project manager can delete task assignments' as message;
            ROLLBACK;
        ELSE
            DELETE FROM task_assignment
            WHERE task_id = p_task_id
              AND employee_id = p_employee_id_to_remove
              AND role_id = p_role_id;
            SELECT 'SUCCESS' as result, 'Task assignment deleted' as message, ROW_COUNT() as rows_affected;
            COMMIT;
        END IF;
    END IF;
END$$

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
            FROM task t
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
                UPDATE task
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
        SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
        
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
            FROM task t
            JOIN project p ON t.project_id = p.id
            LEFT JOIN task_assignment ta ON t.id = ta.task_id AND ta.employee_id = p_employee_id
            LEFT JOIN role r ON ta.role_id = r.id
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
    
    -- Limit 유효성 검사
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
        FROM audit_log a
        LEFT JOIN employee e ON a.employee_id = e.id
        WHERE a.table_name = p_table_name AND a.record_id = p_record_id
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    ELSEIF p_table_name IS NOT NULL THEN
        -- 특정 테이블의 모든 레코드
        SELECT a.*, e.name as employee_name
        FROM audit_log a
        LEFT JOIN employee e ON a.employee_id = e.id
        WHERE a.table_name = p_table_name
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    ELSE
        -- 모든 감사 로그
        SELECT a.*, e.name as employee_name
        FROM audit_log a
        LEFT JOIN employee e ON a.employee_id = e.id
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
            DELETE FROM task WHERE id = p_task_id;
            SELECT 'SUCCESS' as result, 'Task deleted successfully' as message, ROW_COUNT() as rows_affected;
            COMMIT;
        ELSE
            SELECT 'ACCESS_DENIED' as result, 'You do not have permission to delete this task' as message;
            ROLLBACK;
        END IF;
    END IF;
END$$

DELIMITER ;
