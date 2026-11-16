# prueba_maria_DB

Base de datos de un colegio que armé para practicar SQL en MariaDB usando DBeaver CE

## Qué hay

- `colegio.sql` crea la base de datos con las tablas y datos de prueba (creada con IA)
- `scripts_consultas_colegio.sql` tiene los ejercicios de prueba

## Qué practiqué

- Consultas con JOIN de varias tablas, LEFT JOIN, GROUP BY, HAVING y subconsultas.
- Funciones
- Procedimientos almacenados
- Índices

## Cómo probarlo

1. Instalar MariaDB. Para Fedora se coloca este comando:

```bash
sudo dnf install mariadb-server
sudo systemctl enable --now mariadb
```

2. Crear un usuario (si no tienes uno en MariaDB). Primero entrar como administrador:

```bash
sudo mariadb
```

Y crear el usuario con estos comandos SQL:

```sql
CREATE USER 'tu_usuario'@'localhost' IDENTIFIED BY 'tu_contraseña';
GRANT ALL PRIVILEGES ON *.* TO 'tu_usuario'@'localhost';
EXIT;
```

3. Cargar la BD

```bash
mariadb -u tu_usuario -p < colegio.sql
```

Al final muestra cuántas filas tiene cada tabla. Si sale 7, 6, 26, 6, 36 y 438, se cargó bien.

4. Entrar a la BD

```bash
mariadb -u tu_usuario -p colegio
```

5. Instalar DBeaver con estos comandos:

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

```bash
flatpak install flathub io.dbeaver.DBeaverCommunity
```

6. Abrir `scripts_consultas_colegio.sql` en DBeaver y ejecutar los ejercicios.
