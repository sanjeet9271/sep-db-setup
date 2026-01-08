import sys
import os
from pathlib import Path

# Add parent directory to path to import db_config
sys.path.insert(0, str(Path(__file__).parent.parent))

import psycopg2
from psycopg2 import sql
from psycopg2.extras import RealDictCursor
from datetime import datetime
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
            return tables
    except psycopg2.Error as e:
        print(f"Error fetching tables: {e}")
        return []

def get_table_schema(conn, schema_name, table_name):
    """Get detailed schema information for a specific table"""
    query = """
        SELECT 
            column_name,
            data_type,
            character_maximum_length,
            is_nullable,
            column_default,
            ordinal_position
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (schema_name, table_name))
            columns = cur.fetchall()
            return columns
    except psycopg2.Error as e:
        print(f"Error fetching table schema: {e}")
        return []

def get_table_indexes(conn, schema_name, table_name):
    """Get indexes for a specific table"""
    query = """
        SELECT
            i.indexname,
            i.indexdef
        FROM pg_indexes i
        WHERE i.schemaname = %s AND i.tablename = %s;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (schema_name, table_name))
            indexes = cur.fetchall()
            return indexes
    except psycopg2.Error as e:
        print(f"Error fetching indexes: {e}")
        return []

def get_table_constraints(conn, schema_name, table_name):
    """Get constraints for a specific table"""
    query = """
        SELECT
            tc.constraint_name,
            tc.constraint_type,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        LEFT JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.table_schema = %s AND tc.table_name = %s
        ORDER BY tc.constraint_type, tc.constraint_name;
    """
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, (schema_name, table_name))
            constraints = cur.fetchall()
            return constraints
    except psycopg2.Error as e:
        print(f"Error fetching constraints: {e}")
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
        stats['row_count'] = f"Error: {e}"
    
    # Get table size
    try:
        with conn.cursor() as cur:
            query = """
                SELECT 
                    pg_size_pretty(pg_total_relation_size(%s)) as total_size,
                    pg_size_pretty(pg_relation_size(%s)) as table_size,
                    pg_size_pretty(pg_total_relation_size(%s) - pg_relation_size(%s)) as indexes_size
            """
            full_table_name = f"{schema_name}.{table_name}"
            cur.execute(query, (full_table_name, full_table_name, full_table_name, full_table_name))
            result = cur.fetchone()
            stats['total_size'] = result[0]
            stats['table_size'] = result[1]
            stats['indexes_size'] = result[2]
    except psycopg2.Error as e:
        stats['total_size'] = f"Error: {e}"
        stats['table_size'] = "N/A"
        stats['indexes_size'] = "N/A"
    
    return stats

def display_table_info(conn, schema_name, table_name):
    """Display comprehensive information about a table"""
    print("\n" + "="*80)
    print(f"TABLE: {schema_name}.{table_name}")
    print("="*80)
    
    # Get statistics
    print("\n[*] TABLE STATISTICS:")
    print("-" * 80)
    stats = get_table_statistics(conn, schema_name, table_name)
    print(f"  Total Rows:      {stats.get('row_count', 'N/A')}")
    print(f"  Total Size:      {stats.get('total_size', 'N/A')}")
    print(f"  Table Size:      {stats.get('table_size', 'N/A')}")
    print(f"  Indexes Size:    {stats.get('indexes_size', 'N/A')}")
    
    # Get schema
    print("\n[*] COLUMNS:")
    print("-" * 80)
    columns = get_table_schema(conn, schema_name, table_name)
    if columns:
        print(f"{'#':<4} {'Column Name':<30} {'Data Type':<20} {'Nullable':<10} {'Default':<20}")
        print("-" * 80)
        for col in columns:
            pos = col['ordinal_position']
            name = col['column_name']
            dtype = col['data_type']
            if col['character_maximum_length']:
                dtype += f"({col['character_maximum_length']})"
            nullable = col['is_nullable']
            default = col['column_default'] if col['column_default'] else ''
            if len(default) > 18:
                default = default[:15] + "..."
            print(f"{pos:<4} {name:<30} {dtype:<20} {nullable:<10} {default:<20}")
    else:
        print("  No columns found")
    
    # Get constraints
    print("\n[*] CONSTRAINTS:")
    print("-" * 80)
    constraints = get_table_constraints(conn, schema_name, table_name)
    if constraints:
        current_type = None
        for constraint in constraints:
            if constraint['constraint_type'] != current_type:
                current_type = constraint['constraint_type']
                print(f"\n  {current_type}:")
            constraint_name = constraint['constraint_name']
            column_name = constraint['column_name']
            if constraint['foreign_table_name']:
                print(f"    - {constraint_name}: {column_name} -> {constraint['foreign_table_name']}.{constraint['foreign_column_name']}")
            else:
                print(f"    - {constraint_name}: {column_name}")
    else:
        print("  No constraints found")
    
    # Get indexes
    print("\n[*] INDEXES:")
    print("-" * 80)
    indexes = get_table_indexes(conn, schema_name, table_name)
    if indexes:
        for idx in indexes:
            print(f"  - {idx['indexname']}")
            print(f"    {idx['indexdef']}")
    else:
        print("  No indexes found")
    
    print("\n" + "="*80 + "\n")

def main():
    """Main function to run the interactive schema checker"""
    print("\n" + "="*80)
    print("DATABASE SCHEMA CHECKER".center(80))
    print("="*80)
    
    # Connect to database
    print("\n[*] Connecting to database...")
    conn = connect_to_db()
    print("[+] Connected successfully!\n")
    
    try:
        while True:
            # Get all tables
            tables = get_all_tables(conn)
            
            if not tables:
                print("No tables found in the database.")
                break
            
            # Display table list
            print("\n" + "="*80)
            print("AVAILABLE TABLES:")
            print("-" * 80)
            for idx, table in enumerate(tables, 1):
                schema = table['table_schema']
                name = table['table_name']
                table_type = table['table_type']
                print(f"  {idx}. {schema}.{name} ({table_type})")
            print("-" * 80)
            print(f"  0. Exit")
            print("="*80)
            
            # Get user choice
            try:
                choice = input("\nEnter table number to view details (or 0 to exit): ").strip()
                
                if choice == '0':
                    print("\n[*] Goodbye!")
                    break
                
                choice_num = int(choice)
                
                if 1 <= choice_num <= len(tables):
                    selected_table = tables[choice_num - 1]
                    display_table_info(
                        conn, 
                        selected_table['table_schema'], 
                        selected_table['table_name']
                    )
                    
                    # Ask if user wants to continue
                    continue_choice = input("\nPress Enter to continue or 'q' to quit: ").strip().lower()
                    if continue_choice == 'q':
                        print("\n[*] Goodbye!")
                        break
                else:
                    print("\n[-] Invalid choice. Please enter a valid table number.")
                    
            except ValueError:
                print("\n[-] Invalid input. Please enter a number.")
            except KeyboardInterrupt:
                print("\n\n[*] Goodbye!")
                break
                
    finally:
        conn.close()
        print("\n[*] Database connection closed.\n")

if __name__ == "__main__":
    main()

