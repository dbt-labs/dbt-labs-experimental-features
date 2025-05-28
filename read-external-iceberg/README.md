# Reading external, unmanaged Iceberg tables as Sources

> [!WARNING]  
> This feature is experimental and subject to change at any time

An experimental extension to [dbt-labs/dbt-external-tables](https://github.com/dbt-labs/dbt-external-tables) that adds support for creating Iceberg tables pointing to external catalogs unmanaged by the warehouse of a dbt project.

See this discussion for more context


## Supported databases

* Snowflake

## Installation

### Install this project as a package ([package-management docs](https://docs.getdbt.com/docs/building-a-dbt-project/package-management))
  - [Local package](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#local-packages): by referencing this [`read-external-iceberg/`](https://github.com/dbt-labs/dbt-labs-experimental-features/tree/master/read-external-iceberg) folder.
  - [Git package](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#git-packages) using [project subdirectories](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#git-packages): again by referencing the [`read-external-iceberg`](https://github.com/dbt-labs/dbt-labs-experimental-features/tree/master/read-external-iceberg) folder.

### Copy-paste the files from `macros/` into your own project

specifically those in `plugins/snowflake/`


## Configuration

You'll need some form of the below to make sure it works

```yml
dispatch:
  - macro_namespace: dbt
    search_order:
      - <YOUR_PROJECT_NAME>
      - read_external_iceberg #if you're installing as a pacakge
      - dbt_external_tables
      - dbt
```


## Usage

The exact same as [dbt-labs/dbt-external-tables](https://github.com/dbt-labs/dbt-external-tables)!

## Sample usage


```yml
version: 2
sources:
  - name: snowplow
    database: analytics
    schema: snowplow_external
    loader: S3
    loaded_at_field: collector_hour
    
    tables:
      - name: my_iceberg_table
        description: |
          Iceberg table using an external AWS Glue or REST catalog
          Additional Details: https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table#external-iceberg-catalog
        external:
          table_format: iceberg
          # existing external volume
          external_volume: my_external_volume                     
          # existing catalog integration
          catalog: my_catalog_integration
          # name of the table in the external catalog
          catalog_table_name: my_iceberg_table                  
          # namespace of the namespace in the external catalog
          # Hint: in AWS Glue this is the "Database"
          catalog_namespace: my_iceberg_table_namespace
          # optional; Specifies whether to replace invalid UTF-8 characters withthe Unicode replacement character in query results
          replace_invalid_characters: true
          # optional; Specifies whether Snowflake should automatically poll the external Iceberg catalog
          # associated with the table for metadata updates when you use automated refresh
          auto_refresh: true
          # optional; Specifies a co
```