import sys
import os
import json
from pathlib import Path
from datetime import datetime

# Add parent directory to path to import db_config
sys.path.insert(0, str(Path(__file__).parent.parent))

import psycopg2
from psycopg2 import sql
from psycopg2.extras import RealDictCursor
from db_config import load_db_config

def connect_to_db():
    """Establish connection to the database"""
    try:
        config = load_db_config()
        conn = psycopg2.connect(
            host=config['host'],
            port=config['port'],
            database=config['database'],
            user=config['user'],
            password=config['password']
        )
        return conn
    except FileNotFoundError as e:
        print(f"Error: {e}")
        exit(1)
    except psycopg2.Error as e:
        print(f"Error connecting to database: {e}")
        exit(1)

def get_all_tables(conn):
    """Get list of all user tables in the database"""
    query = """
        SELECT 
            table_schema,
            table_name,
            table_type
        FROM information_schema.tables
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
        ORDER BY table_schema, table_name;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            tables = cur.fetchall()
            return [dict(row) for row in tables]
    except psycopg2.Error as e:
        print(f"Error fetching tables: {e}")
        return []

def get_table_columns(conn, schema_name, table_name):
    """Get detailed column information for a specific table"""
    query = """
        SELECT 
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            is_nullable,
            column_default,
            ordinal_position,
            udt_name
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (schema_name, table_name))
            columns = cur.fetchall()
            return [dict(row) for row in columns]
    except psycopg2.Error as e:
        print(f"Error fetching columns for {schema_name}.{table_name}: {e}")
        return []

def get_table_constraints(conn, schema_name, table_name):
    """Get all constraints for a specific table"""
    query = """
        SELECT
            tc.constraint_name,
            tc.constraint_type,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            rc.update_rule,
            rc.delete_rule,
            cc.check_clause
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        LEFT JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        LEFT JOIN information_schema.referential_constraints rc
            ON tc.constraint_name = rc.constraint_name
            AND tc.table_schema = rc.constraint_schema
        LEFT JOIN information_schema.check_constraints cc
            ON tc.constraint_name = cc.constraint_name
            AND tc.table_schema = cc.constraint_schema
        WHERE tc.table_schema = %s AND tc.table_name = %s
        ORDER BY tc.constraint_type, tc.constraint_name, kcu.ordinal_position;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (schema_name, table_name))
            constraints = cur.fetchall()
            return [dict(row) for row in constraints]
    except psycopg2.Error as e:
        print(f"Error fetching constraints for {schema_name}.{table_name}: {e}")
        return []

def get_table_indexes(conn, schema_name, table_name):
    """Get all indexes for a specific table"""
    query = """
        SELECT
            i.indexname,
            i.indexdef,
            ix.indisunique as is_unique,
            ix.indisprimary as is_primary,
            am.amname as index_type
        FROM pg_indexes i
        JOIN pg_class c ON c.relname = i.indexname
        JOIN pg_index ix ON ix.indexrelid = c.oid
        JOIN pg_am am ON am.oid = c.relam
        WHERE i.schemaname = %s AND i.tablename = %s
        ORDER BY i.indexname;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (schema_name, table_name))
            indexes = cur.fetchall()
            return [dict(row) for row in indexes]
    except psycopg2.Error as e:
        print(f"Error fetching indexes for {schema_name}.{table_name}: {e}")
        return []

def get_table_statistics(conn, schema_name, table_name):
    """Get statistics for a specific table"""
    stats = {}
    
    # Get row count
    try:
        with conn.cursor() as cur:
            query = sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                sql.Identifier(schema_name),
                sql.Identifier(table_name)
            )
            cur.execute(query)
            stats['row_count'] = cur.fetchone()[0]
    except psycopg2.Error as e:
        stats['row_count'] = None
        stats['row_count_error'] = str(e)
    
    # Get table size
    try:
        with conn.cursor() as cur:
            query = """
                SELECT 
                    pg_total_relation_size(%s) as total_size_bytes,
                    pg_relation_size(%s) as table_size_bytes,
                    pg_total_relation_size(%s) - pg_relation_size(%s) as indexes_size_bytes,
                    pg_size_pretty(pg_total_relation_size(%s)) as total_size,
                    pg_size_pretty(pg_relation_size(%s)) as table_size,
                    pg_size_pretty(pg_total_relation_size(%s) - pg_relation_size(%s)) as indexes_size
            """
            full_table_name = f"{schema_name}.{table_name}"
            params = [full_table_name] * 8
            cur.execute(query, params)
            result = cur.fetchone()
            stats['total_size_bytes'] = result[0]
            stats['table_size_bytes'] = result[1]
            stats['indexes_size_bytes'] = result[2]
            stats['total_size'] = result[3]
            stats['table_size'] = result[4]
            stats['indexes_size'] = result[5]
    except psycopg2.Error as e:
        stats['size_error'] = str(e)
    
    return stats

def export_database_schema(conn, output_file='database_schema.json'):
    """Export complete database schema to JSON file"""
    print("\n[*] Starting database schema export...")
    
    schema_export = {
        'export_metadata': {
            'timestamp': datetime.now().isoformat(),
            'database': conn.info.dbname,
            'host': conn.info.host,
            'port': conn.info.port
        },
        'tables': []
    }
    
    # Get all tables
    tables = get_all_tables(conn)
    print(f"[*] Found {len(tables)} tables to export")
    
    for table in tables:
        schema_name = table['table_schema']
        table_name = table['table_name']
        print(f"[*] Processing: {schema_name}.{table_name}")
        
        table_info = {
            'schema': schema_name,
            'name': table_name,
            'type': table['table_type'],
            'columns': get_table_columns(conn, schema_name, table_name),
            'constraints': get_table_constraints(conn, schema_name, table_name),
            'indexes': get_table_indexes(conn, schema_name, table_name),
            'statistics': get_table_statistics(conn, schema_name, table_name)
        }
        
        schema_export['tables'].append(table_info)
    
    # Write to JSON file
    output_path = Path(__file__).parent / output_file
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(schema_export, f, indent=2, default=str)
    
    print(f"\n[+] Schema exported successfully to: {output_path}")
    print(f"[+] Total tables exported: {len(tables)}")
    
    return output_path

def main():
    """Main function"""
    print("\n" + "="*80)
    print("DATABASE SCHEMA EXPORT TO JSON".center(80))
    print("="*80)
    
    # Connect to database
    print("\n[*] Connecting to database...")
    conn = connect_to_db()
    print("[+] Connected successfully!")
    
    try:
        # Export schema
        output_file = export_database_schema(conn)
        
        # Print summary
        print("\n" + "="*80)
        print("EXPORT COMPLETE".center(80))
        print("="*80)
        print(f"\nOutput file: {output_file}")
        print(f"File size: {output_file.stat().st_size / 1024:.2f} KB")
        print("\nYou can now use this JSON file for documentation or analysis.")
        
    finally:
        conn.close()
        print("\n[*] Database connection closed.\n")

if __name__ == "__main__":
    main()
