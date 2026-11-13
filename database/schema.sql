-- Banco de dados do projeto BarberFlow
-- SGBD: MySQL 8.0+
-- Observacao: o relatorio original descreve armazenamento em localStorage.
-- Este banco representa uma extensao para persistencia em MySQL.

CREATE DATABASE IF NOT EXISTS barberflow
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE barberflow;

-- 1. Cadastro de clientes
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20) NOT NULL
);

-- 2. Cadastro de servicos e precos
CREATE TABLE IF NOT EXISTS servicos (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_servicos_preco CHECK (preco >= 0)
);

-- 3. Fila de atendimento.
-- O menor id_fila representa a solicitacao que entrou primeiro (FIFO).
CREATE TABLE IF NOT EXISTS fila_atendimento (
    id_fila BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_servico INT NOT NULL,
    data_entrada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fila_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_fila_servico
        FOREIGN KEY (id_servico) REFERENCES servicos(id_servico)
);

CREATE INDEX idx_fila_ordem ON fila_atendimento (id_fila);

-- 4. Historico dos atendimentos concluidos.
-- preco_cobrado guarda o valor no momento do atendimento,
-- mesmo que o preco do servico seja alterado posteriormente.
CREATE TABLE IF NOT EXISTS atendimentos (
    id_atendimento BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_servico INT NOT NULL,
    preco_cobrado DECIMAL(10,2) NOT NULL,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_atendimento_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_atendimento_servico
        FOREIGN KEY (id_servico) REFERENCES servicos(id_servico),
    CONSTRAINT chk_atendimento_preco CHECK (preco_cobrado >= 0)
);

CREATE INDEX idx_atendimentos_data ON atendimentos (data_hora);

-- CONSULTAS PRINCIPAIS

-- Cadastrar cliente:
-- INSERT INTO clientes (nome, telefone)
-- VALUES ('Ana', '(82) 99999-9999');

-- Cadastrar servico:
-- INSERT INTO servicos (nome, preco)
-- VALUES ('Corte', 30.00);

-- Colocar um cliente na fila (substitua os IDs):
-- INSERT INTO fila_atendimento (id_cliente, id_servico)
-- VALUES (1, 1);

-- Consultar a fila na ordem de chegada:
SELECT
    f.id_fila,
    c.nome AS cliente,
    s.nome AS servico,
    s.preco,
    f.data_entrada
FROM fila_atendimento AS f
JOIN clientes AS c ON c.id_cliente = f.id_cliente
JOIN servicos AS s ON s.id_servico = f.id_servico
ORDER BY f.id_fila ASC;

-- Visualizar o proximo cliente:
SELECT
    f.id_fila,
    c.nome AS cliente,
    s.nome AS servico,
    s.preco
FROM fila_atendimento AS f
JOIN clientes AS c ON c.id_cliente = f.id_cliente
JOIN servicos AS s ON s.id_servico = f.id_servico
ORDER BY f.id_fila ASC
LIMIT 1;

-- Finalizar o atendimento do primeiro da fila:
-- Execute as instrucoes abaixo como uma unica transacao.
-- START TRANSACTION;
-- SET @fila_id = (
--     SELECT id_fila
--     FROM fila_atendimento
--     ORDER BY id_fila ASC
--     LIMIT 1
-- );
-- INSERT INTO atendimentos (id_cliente, id_servico, preco_cobrado)
-- SELECT id_cliente, id_servico, (SELECT preco FROM servicos
--                                WHERE servicos.id_servico = fila_atendimento.id_servico)
-- FROM fila_atendimento
-- WHERE id_fila = @fila_id;
-- DELETE FROM fila_atendimento WHERE id_fila = @fila_id;
-- COMMIT;

-- Relatorio: quantidade de atendimentos, servicos realizados e faturamento:
SELECT
    COUNT(*) AS total_atendimentos,
    COUNT(DISTINCT id_servico) AS tipos_de_servico,
    COALESCE(SUM(preco_cobrado), 0) AS total_faturado
FROM atendimentos;

-- Historico detalhado:
SELECT
    a.id_atendimento,
    c.nome AS cliente,
    s.nome AS servico,
    a.preco_cobrado,
    a.data_hora
