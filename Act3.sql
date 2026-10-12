
/*
ACTIVIDAD 3 - MANUAL TECNICO COLABORATIVO Y CONTROL DDL
Base de datos: Northwind
Este script consulta metadatos; no crea, modifica ni elimina objetos.
Los numeros de estos comentarios coinciden con los apartados del documento.
*/

USE Northwind;
GO

-- 1. INFORMACION GENERAL DE LA BASE DE DATOS
SELECT
    DB_NAME() AS BaseDeDatosActual,
    @@SERVERNAME AS NombreServidor,
    CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) AS VersionSQLServer,
    CAST(SERVERPROPERTY('Edition') AS varchar(100)) AS EdicionSQLServer,
    GETDATE() AS FechaConsulta;
GO

-- 2. ESQUEMAS DE LA BASE DE DATOS
SELECT
    s.name AS NombreEsquema,
    USER_NAME(s.principal_id) AS Propietario
FROM sys.schemas AS s
ORDER BY s.name;
GO

-- 3. TABLAS, VISTAS Y PROCEDIMIENTOS
SELECT
    sc.name AS Esquema,
    o.name AS NombreObjeto,
    o.type_desc AS TipoObjeto,
    o.create_date AS FechaCreacion,
    o.modify_date AS FechaUltimaModificacion
FROM sys.objects AS o
INNER JOIN sys.schemas AS sc ON sc.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF')
ORDER BY sc.name, o.type_desc, o.name;
GO

-- 4. COLUMNAS Y TIPOS DE DATOS DE LAS TABLAS
SELECT
    sc.name AS Esquema,
    t.name AS Tabla,
    c.column_id AS NumeroColumna,
    c.name AS Columna,
    ty.name AS TipoDato,
    c.max_length AS LongitudMaximaBytes,
    c.is_nullable AS PermiteNulos,
    c.is_identity AS EsIdentity
FROM sys.tables AS t
INNER JOIN sys.schemas AS sc ON sc.schema_id = t.schema_id
INNER JOIN sys.columns AS c ON c.object_id = t.object_id
INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY sc.name, t.name, c.column_id;
GO

-- 5. RELACIONES ENTRE TABLAS (CLAVES FORANEAS)
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS EsquemaTablaOrigen,
    OBJECT_NAME(fk.parent_object_id) AS TablaOrigen,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnaOrigen,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS EsquemaTablaDestino,
    OBJECT_NAME(fk.referenced_object_id) AS TablaDestino,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ColumnaDestino,
    fk.name AS NombreRelacion
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fkc.constraint_object_id = fk.object_id
ORDER BY TablaOrigen, NombreRelacion;
GO

-- 6. DEPENDENCIAS ENTRE OBJETOS SQL
SELECT
    OBJECT_SCHEMA_NAME(d.referencing_id) AS EsquemaObjeto,
    OBJECT_NAME(d.referencing_id) AS ObjetoQueHaceReferencia,
    o.type_desc AS TipoObjeto,
    d.referenced_schema_name AS EsquemaReferenciado,
    d.referenced_entity_name AS ObjetoReferenciado,
    d.is_caller_dependent AS DependeDelLlamador
FROM sys.sql_expression_dependencies AS d
LEFT JOIN sys.objects AS o ON o.object_id = d.referencing_id
WHERE d.referencing_id IS NOT NULL
ORDER BY EsquemaObjeto, ObjetoQueHaceReferencia, ObjetoReferenciado;
GO

-- 7. PERMISOS REGISTRADOS EN LA BASE DE DATOS
SELECT
    USER_NAME(p.grantee_principal_id) AS UsuarioORol,
    p.state_desc AS EstadoPermiso,
    p.permission_name AS Permiso,
    p.class_desc AS TipoObjeto,
    CASE
        WHEN p.class = 0 THEN DB_NAME()
        WHEN p.class = 1 THEN
            CONCAT(OBJECT_SCHEMA_NAME(p.major_id), '.', OBJECT_NAME(p.major_id))
        WHEN p.class = 3 THEN SCHEMA_NAME(p.major_id)
        ELSE CONVERT(varchar(20), p.major_id)
    END AS Objeto
FROM sys.database_permissions AS p
ORDER BY UsuarioORol, TipoObjeto, Objeto, Permiso;
GO

-- 8. DESCRIPCIONES DOCUMENTADAS EN PROPIEDADES EXTENDIDAS
SELECT
    CASE
        WHEN ep.major_id = 0 THEN 'BASE DE DATOS'
        WHEN o.object_id IS NOT NULL THEN o.type_desc
        ELSE 'OTRO'
    END AS TipoObjeto,
    OBJECT_SCHEMA_NAME(ep.major_id) AS Esquema,
    OBJECT_NAME(ep.major_id) AS Objeto,
    ep.name AS NombrePropiedad,
    CONVERT(nvarchar(4000), ep.value) AS Descripcion
FROM sys.extended_properties AS ep
LEFT JOIN sys.objects AS o ON o.object_id = ep.major_id
WHERE ep.name = 'MS_Description'
ORDER BY Esquema, Objeto;
GO

-- 9. REVISAR FECHAS DE MODIFICACION DE LOS OBJETOS
-- Estas fechas ayudan a localizar cambios, pero no sustituyen un historial de Git.
SELECT
    sc.name AS Esquema,
    o.name AS Objeto,
    o.type_desc AS TipoObjeto,
    o.create_date AS FechaCreacion,
    o.modify_date AS FechaModificacion
FROM sys.objects AS o
INNER JOIN sys.schemas AS sc ON sc.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY o.modify_date DESC, sc.name, o.name;
GO
