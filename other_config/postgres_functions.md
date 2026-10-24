Here is a complete rundown on **Functions** and **Triggers** in PostgreSQL, how to create and drop them, and what statements/functions you can use between `BEGIN` and `END`.

---

# 1. Functions in PostgreSQL

### What is a Function?
A function (often written in PL/pgSQL) is a reusable block of code that takes zero or more inputs, performs operations/computations, and optionally returns a result (a single value, a record, or an entire table/set of rows).

### How to Create a Function
PostgreSQL uses `$$` (dollar-quoting) to contain the function body so you don’t have to escape quotes inside.

```sql
CREATE OR REPLACE FUNCTION calculate_discount(price NUMERIC, discount_percent NUMERIC)
RETURNS NUMERIC 
LANGUAGE plpgsql
AS $$
DECLARE
    discounted_price NUMERIC;
BEGIN
    discounted_price := price - (price * (discount_percent / 100));
    RETURN discounted_price;
END;
$$;
```

*Calling it:*
```sql
SELECT calculate_discount(100.00, 15); -- Returns 85.00
```

### How to Drop a Function
Because PostgreSQL supports **function overloading** (multiple functions can have the same name if they have different parameter types), you must specify the parameter types when dropping:

```sql
-- Syntax: DROP FUNCTION [IF EXISTS] function_name(param_types);
DROP FUNCTION IF EXISTS calculate_discount(NUMERIC, NUMERIC);
```
*(If the function has no overloads, you can sometimes drop it without parameter types in modern PostgreSQL, but specifying the types is best practice.)*

---

# 2. Triggers in PostgreSQL

### What is a Trigger?
A trigger is a database mechanism that **automatically executes** a specific function when a particular event occurs (`INSERT`, `UPDATE`, `DELETE`, or `TRUNCATE`) on a table or view.

In PostgreSQL, creating a trigger is a **two-step process**:
1. Create a **Trigger Function** that returns the special type `TRIGGER`.
2. Create the **Trigger** itself and bind it to a table.

### How to Create a Trigger

#### Step 1: Create the Trigger Function
Trigger functions take no parameters and return `TRIGGER`. They have access to special variables like `NEW` (the row being inserted/updated) and `OLD` (the row before update/delete).

```sql
CREATE OR REPLACE FUNCTION log_employee_update()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the 'last_modified' column automatically
    NEW.last_modified := NOW();
    
    -- Return NEW for BEFORE triggers so the modified row is saved
    RETURN NEW;
END;
$$;
```

#### Step 2: Create the Trigger
Bind the function to the table using `CREATE TRIGGER`:

```sql
CREATE TRIGGER trigger_update_employee_timestamp
BEFORE UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION log_employee_update();
```
*(Note: Older Postgres versions also accepted `EXECUTE PROCEDURE`, but `EXECUTE FUNCTION` is standard in modern PostgreSQL.)*

### How to Drop a Trigger
Unlike functions, triggers are scoped directly to tables. You must specify the table name:

```sql
-- Syntax: DROP TRIGGER [IF EXISTS] trigger_name ON table_name;
DROP TRIGGER IF EXISTS trigger_update_employee_timestamp ON employees;
```
If you also want to remove the underlying trigger function:
```sql
DROP FUNCTION IF EXISTS log_employee_update();
```

---

# 3. What Can Be Used Between `BEGIN` and `END`?

Between `BEGIN` and `END`, you are writing **PL/pgSQL code**. You can use ordinary SQL statements, procedural control flow, special variables, built-in functions, and error handling.

Here is a breakdown of the key tools and statements available:

---

### A. Assigning & Querying Data

* **Assignment (`:=` or `=`):**
  ```sql
  total := a + b;
  ```
* **`SELECT INTO` (Storing query results into variables):**
  ```sql
  SELECT salary, dept_id INTO emp_salary, emp_dept 
  FROM employees 
  WHERE id = emp_id;
  ```
* **`PERFORM` (Run a query and discard the result):**
  If you want to call an SQL function or run a query without saving the output (since plain `SELECT` will cause an error if results are not assigned):
  ```sql
  PERFORM update_account_balance(user_id);
  ```
* **`EXECUTE` (Dynamic SQL):**
  Allows you to build and run queries dynamically at runtime:
  ```sql
  EXECUTE 'SELECT count(*) FROM ' || quote_ident(dynamic_table_name) INTO row_count;
  ```

---

### B. Control Flow (Conditions & Loops)

* **Conditionals (`IF / ELSIF / ELSE`):**
  ```sql
  IF score >= 90 THEN
      grade := 'A';
  ELSIF score >= 80 THEN
      grade := 'B';
  ELSE
      grade := 'F';
  END IF;
  ```
* **`CASE` Statements:**
  ```sql
  CASE status
      WHEN 'A' THEN status_text := 'Active';
      WHEN 'I' THEN status_text := 'Inactive';
      ELSE status_text := 'Unknown';
  END CASE;
  ```
* **Loops:**
  * Simple loop:
    ```sql
    LOOP
        counter := counter + 1;
        EXIT WHEN counter > 10;
    END LOOP;
    ```
  * While loop:
    ```sql
    WHILE counter < 10 LOOP
        counter := counter + 1;
    END LOOP;
    ```
  * Range loop:
    ```sql
    FOR i IN 1..10 LOOP
        -- do something
    END LOOP;
    ```
  * Query Loop (Iterating over rows):
    ```sql
    FOR emp_record IN SELECT id, salary FROM employees LOOP
        -- emp_record.id, emp_record.salary
    END LOOP;
    ```

---

### C. Returning Values & Results

* **`RETURN expression;`**: Returns a single scalar or composite value and ends the function.
* **`RETURN;`**: Exits a `void` function or trigger.
* **`RETURN NEXT expression;` / `RETURN QUERY query;`**: Used in table-returning functions (`RETURNS TABLE(...)` or `RETURNS SETOF ...`) to stream multiple rows back.
* **In Triggers:**
  * `RETURN NEW;` (saves the new/updated row).
  * `RETURN OLD;` (usually returned in `AFTER DELETE`).
  * `RETURN NULL;` (in a `BEFORE` trigger, cancels the operation for that row!).

---

### D. Printing & Debugging (`RAISE`)

To print debug messages or throw errors, use `RAISE`:
* **`RAISE NOTICE 'User % has logged in at %', user_name, NOW();`** (Prints an informational message to the client).
* **`RAISE WARNING 'Approaching quota limit: %', current_usage;`**
* **`RAISE EXCEPTION 'Invalid ID: %', emp_id;`** (Aborts the transaction and rolls back changes).

---

### E. Special Built-in Status Variables

PostgreSQL provides automatic variables inside PL/pgSQL blocks:
* **`FOUND`**: A boolean variable set to `TRUE` if the previous `SELECT INTO`, `INSERT`, `UPDATE`, or `DELETE` affected or returned at least one row.
  ```sql
  SELECT id INTO found_id FROM users WHERE email = input_email;
  IF NOT FOUND THEN
      RAISE EXCEPTION 'User not found';
  END IF;
  ```
* **`GET DIAGNOSTICS`**: Used to get detailed information about the last command:
  ```sql
  GET DIAGNOSTICS rows_updated = ROW_COUNT;
  ```

---

### F. Special Variables Inside Trigger Functions

When a function is executed by a trigger, PostgreSQL injects these variables automatically:
* **`NEW`**: Record holding the row for `INSERT`/`UPDATE` operations in row-level triggers.
* **`OLD`**: Record holding the row for `UPDATE`/`DELETE` operations in row-level triggers.
* **`TG_OP`**: String telling you which event triggered it (`'INSERT'`, `'UPDATE'`, `'DELETE'`, or `'TRUNCATE'`).
  ```sql
  IF TG_OP = 'DELETE' THEN
      -- use OLD
  ELSIF TG_OP = 'UPDATE' THEN
      -- compare OLD and NEW
  END IF;
  ```
* **`TG_TABLE_NAME`**: Name of the table that triggered the function.
* **`TG_WHEN`**: `'BEFORE'`, `'AFTER'`, or `'INSTEAD OF'`.
* **`TG_LEVEL`**: `'ROW'` or `'STATEMENT'`.
* **`TG_ARGV[0]`, `TG_NARGS`**: Arguments passed to the trigger during `CREATE TRIGGER`.

---

### G. Important PostgreSQL Built-in Functions Commonly Used

You can call any standard PostgreSQL function inside your `BEGIN ... END` block:

1. **Safety / Null-Handling:**
   * `COALESCE(val1, val2, ...)` — returns the first non-null value.
   * `NULLIF(val1, val2)` — returns `NULL` if `val1 = val2`.
2. **String & Formatting:**
   * `format('SELECT * FROM %I WHERE id = %L', table_name, user_id)` — Essential for building safe dynamic SQL.
   * `quote_ident()`, `quote_literal()` — Sanitizes inputs against SQL injection.
   * `concat()`, `lower()`, `upper()`, `trim()`, `substr()`.
3. **Date & Time:**
   * `NOW()`, `CURRENT_TIMESTAMP`, `clock_timestamp()`.
   * `date_trunc('day', timestamp)`, `age(timestamp1, timestamp2)`.
4. **JSON Handling:**
   * `to_jsonb(record)` — converts rows into JSON objects.
   * `jsonb_build_object('key', value, ...)`.

---

### H. Exception Handling (`EXCEPTION`)

You can catch errors before the transaction terminates by adding an `EXCEPTION` section at the end of the `BEGIN ... END` block:

```sql
BEGIN
    INSERT INTO users(email) VALUES (new_email);
EXCEPTION 
    WHEN unique_violation THEN
        RAISE NOTICE 'Email % already exists!', new_email;
    WHEN OTHERS THEN
        RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
END;
```

---

### Quick Summary Cheat Sheet

| Task | Functions | Triggers |
| :--- | :--- | :--- |
| **Purpose** | Reusable logic executed explicitly | Automatic logic fired by table events |
| **Creation** | `CREATE FUNCTION name(...) RETURNS type` | 1. Function `RETURNS TRIGGER`<br>2. `CREATE TRIGGER ... ON table` |
| **Drop Syntax** | `DROP FUNCTION name(arg_types);` | `DROP TRIGGER name ON table_name;` |
| **Inside Body** | `SELECT INTO`, `IF/ELSE`, `LOOPS`, `RETURN` | Same + `NEW`, `OLD`, `TG_OP`, `RETURN NEW/OLD` |
