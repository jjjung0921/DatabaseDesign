CREATE DATABASE IF NOT EXISTS pmis_db;
USE pmis_db;

-- Base tables
CREATE TABLE IF NOT EXISTS department (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    can_read TINYINT(1) NOT NULL DEFAULT 1,
    can_write TINYINT(1) NOT NULL DEFAULT 0,
    can_delete TINYINT(1) NOT NULL DEFAULT 0
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
    status VARCHAR(50) NOT NULL,
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
