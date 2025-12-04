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