USE pmis_db;

-- 필수 역할 값 시드 (권한 컬럼 포함)
INSERT IGNORE INTO role (name, can_read, can_write, can_delete) VALUES
('ADMIN', 1, 1, 1),
('MANAGER', 1, 1, 0),
('MEMBER', 1, 1, 0),
('VIEWER', 1, 0, 0);
