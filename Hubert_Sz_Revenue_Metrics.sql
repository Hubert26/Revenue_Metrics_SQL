-- Sprawdzenie zakresu dat i płatności w tabeli games_payments
SELECT 
    MIN(gp.payment_date) AS earliest_date,
    MAX(gp.payment_date) AS latest_date,
    MAX(gp.revenue_amount_usd) AS biggest_payment,
    MIN(gp.revenue_amount_usd) AS lowest_payment
FROM project.games_payments AS gp;


-- Sprawdzenie wartości wieku
SELECT  
    MAX(gpu.age) as biggest_age,
    MIN(gpu.age) as lowest_age
FROM project.games_paid_users as gpu;

-- Sprawdzenie nietypowych wartości języka
SELECT 
    DISTINCT language
FROM project.games_paid_users;

-- Sprawdzenie użytkowników w games_paid_users, którzy nie mają odpowiednika w games_payments
SELECT 
    gpu.user_id, 
    gpu.game_name
FROM project.games_paid_users AS gpu
LEFT JOIN project.games_payments AS gp 
    ON gp.user_id = gpu.user_id AND gp.game_name = gpu.game_name
WHERE gp.user_id IS NULL;

-- Sprawdzenie użytkowników w games_payments, którzy nie mają odpowiednika w games_paid_users
SELECT 
    gp.user_id, 
    gp.game_name
FROM project.games_payments AS gp
LEFT JOIN project.games_paid_users AS gpu 
    ON gpu.user_id = gp.user_id AND gpu.game_name = gp.game_name
WHERE gpu.user_id IS NULL;


-- Usuń tabelę, jeśli już istnieje
DROP TABLE IF EXISTS public.HS_final_project_TABLE1;

-- Tworzenie nowej tabeli i wstawianie danych
CREATE TABLE public.HS_final_project_TABLE1 AS
SELECT 
    gpu.user_id,
    gpu.game_name,
    gp.payment_date,
    gp.revenue_amount_usd,
    gpu.language,
    gpu.has_older_device_model,
    gpu.age
FROM 
    project.games_paid_users AS gpu 
LEFT JOIN 
    project.games_payments AS gp 
ON 
    gp.user_id = gpu.user_id AND gp.game_name = gpu.game_name;


   

-- Usuń tabelę, jeśli już istnieje
DROP TABLE IF EXISTS public.HS_final_project_TABLE2;

-- Utworzenie tabeli HS_final_project_TABLE2 na podstawie obliczeń
CREATE TABLE public.HS_final_project_TABLE2 AS
WITH revenue_per_month AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', payment_date) AS month,
        SUM(revenue_amount_usd) AS total_revenue 
    FROM 
        public.HS_final_project_TABLE1 AS fpT1
    GROUP BY 
        user_id, DATE_TRUNC('month', payment_date)
)
SELECT 
    user_id,
    month,
    total_revenue,
    LEAD(total_revenue) OVER (PARTITION BY user_id ORDER BY month) AS next_month_revenue,
    LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY month) AS prev_month_revenue,
    LEAD(total_revenue) OVER (PARTITION BY user_id ORDER BY month) - total_revenue AS revenue_next_actual_difference,
    total_revenue - LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY month) AS revenue_actual_prev_difference
FROM 
    revenue_per_month
ORDER BY 
    user_id, month;


