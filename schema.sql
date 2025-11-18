DROP DATABASE IF EXISTS app;
CREATE DATABASE app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE app;

CREATE TABLE id_sequences (
  name VARCHAR(50) PRIMARY KEY,
  seq_value BIGINT NOT NULL
);

INSERT INTO id_sequences (name, seq_value) VALUES
('usuario_seq', 0),
('tarefa_seq', 0);

DELIMITER $$

CREATE PROCEDURE next_sequence(
    IN seq_name VARCHAR(50),
    OUT new_value BIGINT
)
BEGIN
    START TRANSACTION;

    SELECT seq_value INTO new_value
    FROM id_sequences
    WHERE name = seq_name
    FOR UPDATE;

    SET new_value = new_value + 1;

    UPDATE id_sequences
    SET seq_value = new_value
    WHERE name = seq_name;

    COMMIT;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE gerar_usuario_id(OUT novo_id VARCHAR(20))
BEGIN
    DECLARE seq BIGINT;
    CALL next_sequence('usuario_seq', seq);
    SET novo_id = CONCAT('U-', LPAD(seq, 6, '0'));
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE gerar_tarefa_id(OUT novo_id VARCHAR(32))
BEGIN
    DECLARE seq BIGINT;
    CALL next_sequence('tarefa_seq', seq);
    SET novo_id = CONCAT(
        'T-',
        DATE_FORMAT(CURRENT_DATE(), '%Y%m%d'),
        '-',
        LPAD(seq, 5, '0')
    );
END$$

DELIMITER ;

CREATE TABLE grupos_usuarios (
  id_grupo VARCHAR(16) PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  descricao TEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuarios (
  id_usuario VARCHAR(20) PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  email VARCHAR(200) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  id_grupo VARCHAR(16) NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NULL,
  FOREIGN KEY (id_grupo) REFERENCES grupos_usuarios(id_grupo)
);

CREATE TABLE categorias_tarefas (
  id_categoria VARCHAR(16) PRIMARY KEY,
  nome VARCHAR(100) NOT NULL
);

CREATE TABLE tarefas (
  id_tarefa VARCHAR(32) PRIMARY KEY,
  titulo VARCHAR(200) NOT NULL,
  descricao TEXT,
  status ENUM('pendente','em_andamento','concluida','cancelada') DEFAULT 'pendente',
  prioridade TINYINT DEFAULT 3,
  id_categoria VARCHAR(16),
  id_usuario_responsavel VARCHAR(20),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NULL,
  FOREIGN KEY (id_categoria) REFERENCES categorias_tarefas(id_categoria),
  FOREIGN KEY (id_usuario_responsavel) REFERENCES usuarios(id_usuario)
);

CREATE TABLE auditoria_tarefas (
  id_aud BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_tarefa VARCHAR(32),
  acao ENUM('INSERT','UPDATE','DELETE'),
  dados_anteriores JSON NULL,
  dados_novos JSON NULL,
  usuario_executou VARCHAR(20) NULL,
  quando TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tarefas_status ON tarefas(status);
CREATE INDEX idx_tarefas_prioridade ON tarefas(prioridade);
CREATE INDEX idx_tarefas_usuario ON tarefas(id_usuario_responsavel);
CREATE INDEX idx_tarefas_categoria ON tarefas(id_categoria);

DELIMITER $$

CREATE TRIGGER trg_tarefas_before_insert
BEFORE INSERT ON tarefas
FOR EACH ROW
BEGIN
  IF NEW.titulo IS NULL OR CHAR_LENGTH(TRIM(NEW.titulo)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Titulo da tarefa não pode ser vazio';
  END IF;

  IF NEW.id_tarefa IS NULL OR NEW.id_tarefa = '' THEN
    CALL gerar_tarefa_id(NEW.id_tarefa);
  END IF;
END$$

CREATE TRIGGER trg_tarefas_after_insert
AFTER INSERT ON tarefas
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_tarefas (id_tarefa, acao, dados_novos)
  VALUES (NEW.id_tarefa, 'INSERT',
          JSON_OBJECT('titulo', NEW.titulo, 'status', NEW.status));
END$$

CREATE TRIGGER trg_tarefas_after_update
AFTER UPDATE ON tarefas
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_tarefas (id_tarefa, acao, dados_anteriores, dados_novos)
  VALUES (
    OLD.id_tarefa,
    'UPDATE',
    JSON_OBJECT('titulo', OLD.titulo, 'status', OLD.status, 'prioridade', OLD.prioridade),
    JSON_OBJECT('titulo', NEW.titulo, 'status', NEW.status, 'prioridade', NEW.prioridade)
  );
END$$

DELIMITER ;

CREATE VIEW vw_tarefas_pendentes AS
SELECT id_tarefa, titulo, prioridade, status, id_usuario_responsavel, criado_em
FROM tarefas
WHERE status = 'pendente';

CREATE VIEW vw_resumo_tarefas AS
SELECT status, COUNT(*) AS total, AVG(prioridade) AS prioridade_media
FROM tarefas
GROUP BY status;

DELIMITER $$

CREATE PROCEDURE sp_criar_tarefa(
  IN p_titulo VARCHAR(200),
  IN p_descricao TEXT,
  IN p_prioridade TINYINT,
  IN p_id_categoria VARCHAR(16),
  IN p_responsavel VARCHAR(20),
  OUT p_id_tarefa VARCHAR(32)
)
BEGIN
  CALL gerar_tarefa_id(p_id_tarefa);

  INSERT INTO tarefas(id_tarefa, titulo, descricao, prioridade, id_categoria, id_usuario_responsavel)
  VALUES(p_id_tarefa, p_titulo, p_descricao, p_prioridade, p_id_categoria, p_responsavel);
END$$

CREATE PROCEDURE sp_concluir_tarefa(IN p_id_tarefa VARCHAR(32))
BEGIN
  UPDATE tarefas
  SET status = 'concluida', atualizado_em = CURRENT_TIMESTAMP
  WHERE id_tarefa = p_id_tarefa;
END$$

CREATE FUNCTION fn_usuario_eh_admin(p_id_usuario VARCHAR(20))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE g VARCHAR(16);
  SELECT id_grupo INTO g FROM usuarios WHERE id_usuario = p_id_usuario;
  RETURN (g = 'ADM');
END$$

DELIMITER ;

CREATE USER IF NOT EXISTS 'app_user'@'localhost' IDENTIFIED BY 'senha_app';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON app.* TO 'app_user'@'localhost';

CREATE USER IF NOT EXISTS 'report_user'@'localhost' IDENTIFIED BY 'senha_report';
GRANT SELECT ON app.* TO 'report_user'@'localhost';

CREATE USER IF NOT EXISTS 'dba_user'@'localhost' IDENTIFIED BY 'senha_dba';
GRANT ALL PRIVILEGES ON app.* TO 'dba_user'@'localhost';

FLUSH PRIVILEGES;

INSERT INTO grupos_usuarios VALUES
('ADM','Administradores','Acesso total',NOW()),
('USR','Usuários','Acesso padrão',NOW());

SET @id_user = '';
CALL gerar_usuario_id(@id_user);

INSERT INTO usuarios (id_usuario, nome, email, senha_hash, id_grupo)
VALUES (@id_user, 'Samuel Teste', 'samuel@example.com', '$2a$10$gF3UULpU9R2yptGRo0zOQO3Z8jYLwILlBN6KWd6oRm3xuGpKaAh3W', 'ADM');

INSERT INTO categorias_tarefas VALUES ('CAT-GEN','Geral');

