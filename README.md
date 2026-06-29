# Proyecto de Data Warehouse y Analytics

Este proyecto demuestra una solución integral de **data warehousing y analítica**, desde la construcción de un data warehouse hasta la generación de insights accionables. Diseñado como un proyecto de portafolio, destaca **buenas prácticas de la industria en ingeniería de datos y análisis de datos**.

---

# Arquitectura de Datos

La arquitectura de datos de este proyecto sigue la **Arquitectura Medallion**, compuesta por las capas **Bronze, Silver y Gold**.

### Bronze Layer
Almacena los **datos crudos (raw data)** tal como provienen de los sistemas fuente.  
Los datos se ingieren desde **archivos CSV hacia una base de datos SQL Server**.

### Silver Layer
Incluye procesos de:

- Limpieza de datos  
- Estandarización  
- Normalización  

Todo esto con el objetivo de **preparar los datos para análisis**.

### Gold Layer
Contiene **datos listos para negocio**, modelados en un **esquema estrella (Star Schema)** requerido para **reporting y analítica**.

---

# Descripción del Proyecto

Este proyecto incluye:

### Data Architecture

![Arquitectura] https://github.com/Luis-Carreno-C/SQL-data-warehouse-Project/blob/a42db499934abfeaf56576af14e92e8b3be56e2e/Docs/Images/Data%20flow%20diagram%20-%20DWH%20Baraa.png

Diseño de un **Data Warehouse moderno** utilizando la arquitectura Medallion (Bronze, Silver, Gold).

### ETL Pipelines
Extracción, transformación y carga de datos desde los sistemas fuente hacia el Data Warehouse.

### Data Modeling
Desarrollo de **tablas de hechos (fact tables)** y **tablas de dimensiones (dimension tables)** optimizadas para consultas analíticas.

### Analytics & Reporting
Creación de **reportes y dashboards basados en SQL** para generar insights accionables.

---

# Requisitos del Proyecto

## Construcción del Data Warehouse (Data Engineering)

### Objetivo

Desarrollar un **Data Warehouse moderno usando SQL Server** para consolidar datos de ventas, permitiendo **reportes analíticos y toma de decisiones informada**.

### Especificaciones

**Data Sources**

Importar datos desde dos sistemas fuente:

- ERP  
- CRM  

Ambos provistos como **archivos CSV**.

**Data Quality**

Limpiar y resolver problemas de **calidad de datos** antes del análisis.

**Integration**

Combinar ambas fuentes en un **modelo de datos único y amigable**, diseñado para consultas analíticas.

**Scope**

Enfocarse solo en el **dataset más reciente**.  
No se requiere **historificación de datos**.

**Documentation**

Proveer documentación clara del **modelo de datos** para apoyar tanto a:

- Stakeholders de negocio  
- Equipos de analítica

---

## BI: Analítica y Reporting (Data Analysis)

### Objetivo

Desarrollar **analítica basada en SQL** para generar insights detallados sobre:

- Comportamiento de clientes  
- Desempeño de productos  
- Tendencias de ventas  

Estos insights permiten a los stakeholders acceder a **métricas clave del negocio**, facilitando la **toma de decisiones estratégicas**.
