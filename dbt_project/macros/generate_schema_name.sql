-- generate_schema_name.sql
-- Override macro dbt agar nama schema persis sesuai custom_schema_name
-- (default dbt menambah prefix target schema, misal: main_bronze)
-- Dengan macro ini: +schema: bronze → schema "bronze" langsung

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
