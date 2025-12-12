USE pmis_db;

-- Role 유효성/권한 헬퍼
DELIMITER $$

CREATE FUNCTION IF NOT EXISTS is_valid_role(p_role VARCHAR(255))
RETURNS TINYINT(1)
DETERMINISTIC
BEGIN
    IF p_role IN ('ADMIN', 'MANAGER', 'MEMBER', 'VIEWER') THEN
        RETURN 1;
    END IF;
    RETURN 0;
END$$

CREATE FUNCTION IF NOT EXISTS role_can_read_tasks(p_role VARCHAR(255))
RETURNS TINYINT(1)
DETERMINISTIC
BEGIN
    DECLARE allowed TINYINT(1) DEFAULT 0;
    SELECT can_read INTO allowed FROM role WHERE name = p_role LIMIT 1;
    IF allowed IS NULL THEN
        SET allowed = 0;
    END IF;
    RETURN allowed;
END$$

CREATE FUNCTION IF NOT EXISTS role_can_write_tasks(p_role VARCHAR(255))
RETURNS TINYINT(1)
DETERMINISTIC
BEGIN
    DECLARE allowed TINYINT(1) DEFAULT 0;
    SELECT can_write INTO allowed FROM role WHERE name = p_role LIMIT 1;
    IF allowed IS NULL THEN
        SET allowed = 0;
    END IF;
    RETURN allowed;
END$$

-- Role 이름 ENUM 강제 트리거
CREATE TRIGGER IF NOT EXISTS role_before_insert
BEFORE INSERT ON role
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR is_valid_role(NEW.name) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role name';
    END IF;
    SET NEW.can_read = IFNULL(NEW.can_read, 1);
    SET NEW.can_write = IFNULL(NEW.can_write, 0);
    SET NEW.can_delete = IFNULL(NEW.can_delete, 0);
END$$

CREATE TRIGGER IF NOT EXISTS role_before_update
BEFORE UPDATE ON role
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR is_valid_role(NEW.name) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role name';
    END IF;
    SET NEW.can_read = IFNULL(NEW.can_read, 1);
    SET NEW.can_write = IFNULL(NEW.can_write, 0);
    SET NEW.can_delete = IFNULL(NEW.can_delete, 0);
END$$

-- 접근 권한 체크 함수

DELIMITER $$

-- Task 조회 권한 체크 함수
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
    
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        RETURN -1;
    END IF;
    
    SELECT COUNT(*) INTO task_exists FROM task WHERE id = p_task_id;
    IF task_exists = 0 THEN
        RETURN -1;
    END IF;
    
    SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    IF EXISTS (
        SELECT 1
        FROM task_assignment ta
        JOIN role r ON ta.role_id = r.id
        WHERE ta.task_id = p_task_id
          AND ta.employee_id = p_employee_id
          AND r.can_read = 1
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
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

-- Task 수정 권한 체크 함수
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
    
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        RETURN -1;
    END IF;
    
    SELECT COUNT(*) INTO task_exists FROM task WHERE id = p_task_id;
    IF task_exists = 0 THEN
        RETURN -1;
    END IF;
    
    SELECT COUNT(*) INTO employee_exists FROM employee WHERE id = p_employee_id;
    IF employee_exists = 0 THEN
        RETURN -1;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM task_assignment ta
        JOIN role r ON ta.role_id = r.id
        WHERE ta.task_id = p_task_id 
        AND ta.employee_id = p_employee_id
        AND r.can_write = 1
    ) THEN
        SET has_permission = 1;
        RETURN has_permission;
    END IF;
    
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

-- Milestone/Task/Risk 등 프로젝트 하위 리소스 수정 시 PM 여부 확인
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

CREATE TRIGGER IF NOT EXISTS task_after_update
AFTER UPDATE ON task
FOR EACH ROW
BEGIN
    DECLARE changes TEXT DEFAULT '';
    
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

-- Resource allocation triggers: keep resource.quantity in sync
CREATE TRIGGER IF NOT EXISTS resource_allocation_before_insert
BEFORE INSERT ON resource_allocation
FOR EACH ROW
BEGIN
    DECLARE available INT;
    IF NEW.amount_used IS NULL OR NEW.amount_used <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'amount_used must be > 0';
    END IF;
    SELECT quantity INTO available FROM resource WHERE id = NEW.resource_id FOR UPDATE;
    IF available IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resource not found';
    END IF;
    IF available < NEW.amount_used THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient resource quantity';
    END IF;
    UPDATE resource SET quantity = quantity - NEW.amount_used WHERE id = NEW.resource_id;
END$$

CREATE TRIGGER IF NOT EXISTS resource_allocation_before_update
BEFORE UPDATE ON resource_allocation
FOR EACH ROW
BEGIN
    DECLARE available INT;
    DECLARE delta INT;
    IF NEW.amount_used IS NULL OR NEW.amount_used <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'amount_used must be > 0';
    END IF;
    IF NEW.resource_id != OLD.resource_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'resource_id cannot be changed';
    END IF;
    SET delta = NEW.amount_used - OLD.amount_used;
    IF delta > 0 THEN
        SELECT quantity INTO available FROM resource WHERE id = NEW.resource_id FOR UPDATE;
        IF available IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resource not found';
        END IF;
        IF available < delta THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient resource quantity';
        END IF;
        UPDATE resource SET quantity = quantity - delta WHERE id = NEW.resource_id;
    ELSEIF delta < 0 THEN
        UPDATE resource SET quantity = quantity - delta WHERE id = NEW.resource_id; -- delta negative, so add back
    END IF;
END$$

CREATE TRIGGER IF NOT EXISTS resource_allocation_after_delete
AFTER DELETE ON resource_allocation
FOR EACH ROW
BEGIN
    UPDATE resource SET quantity = quantity + OLD.amount_used WHERE id = OLD.resource_id;
END$$

DELIMITER ;

-- 권한 기반 조회 VIEW
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
    
    IF p_project_id IS NULL OR p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Project ID and Employee ID cannot be NULL' as message;
        ROLLBACK;
    ELSE
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
    
    IF p_task_id IS NULL OR p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Task ID and Employee ID cannot be NULL' as message;
        ROLLBACK;
    ELSE
        IF p_new_status IS NOT NULL AND p_new_status NOT IN ('TODO', 'DOING', 'DONE') THEN
            SET valid_status = 0;
        END IF;
        
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

CREATE PROCEDURE IF NOT EXISTS get_employee_accessible_tasks(
    IN p_employee_id INT
)
BEGIN
    DECLARE employee_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'ERROR' as result, 'Database error occurred' as message;
    END;
    
    IF p_employee_id IS NULL THEN
        SELECT 'INVALID_INPUT' as result, 'Employee ID cannot be NULL' as message;
    ELSE
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
        SELECT a.*, e.name as employee_name
        FROM audit_log a
        LEFT JOIN employee e ON a.employee_id = e.id
        WHERE a.table_name = p_table_name AND a.record_id = p_record_id
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    ELSEIF p_table_name IS NOT NULL THEN
        SELECT a.*, e.name as employee_name
        FROM audit_log a
        LEFT JOIN employee e ON a.employee_id = e.id
        WHERE a.table_name = p_table_name
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    ELSE
        SELECT a.*, e.name as employee_name
        FROM audit_log a
        LEFT JOIN employee e ON a.employee_id = e.id
        ORDER BY a.changed_at DESC
        LIMIT safe_limit;
    END IF;
END$$

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
