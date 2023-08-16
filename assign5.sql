-- First Exercise:
-- Create a CTE named top_customers that lists the top 10 customers
-- based on the total number of distinct films they've rented

WITH CTE_TOP_CUSTOMERS AS 
(
	SELECT 
		se_customer.customer_id, 
		se_customer.first_name, 
		se_customer.last_name,
		COUNT(DISTINCT se_rental.rental_id) AS films_rented
	FROM customer as se_customer
	INNER JOIN rental as se_rental
		ON se_rental.customer_id = se_customer.customer_id
	GROUP BY se_customer.customer_id
	ORDER BY films_rented
	LIMIT 10
)
-- For each customer from top_customers,
-- retrieve their average payment amount and the count of rentals they've made.
SELECT
	CTE_TOP_CUSTOMERS.customer_id, 
	CTE_TOP_CUSTOMERS.first_name, 
	CTE_TOP_CUSTOMERS.last_name,
	ROUND(AVG(se_payment.amount), 2) AS avg_payment,
	COUNT(se_rental.rental_id) AS rentals_count
FROM CTE_TOP_CUSTOMERS
INNER JOIN rental as se_rental 
	ON se_rental.customer_id = CTE_TOP_CUSTOMERS.customer_id
INNER JOIN payment as se_payment
	ON se_payment.rental_id = se_rental.rental_id
GROUP BY CTE_TOP_CUSTOMERS.customer_id, CTE_TOP_CUSTOMERS.first_name, CTE_TOP_CUSTOMERS.last_name
ORDER BY rentals_count DESC
LIMIT 10

-- Second Exercise:
-- Create a Temporary Table named film_inventory that stores film titles 
-- and their corresponding available inventory count.

DROP TABLE IF EXISTS temp_film_inventory;
CREATE TEMPORARY TABLE temp_film_inventory AS
(
	SELECT 
		se_film.film_id,
		se_film.title, 
		COUNT(se_inventory.inventory_id) as inventory_count
	FROM film as se_film
	RIGHT JOIN inventory as se_inventory  
		ON se_inventory.film_id = se_film.film_id
	GROUP BY se_film.film_id, se_film.title
);

CREATE INDEX idx_temp_film_inventory ON temp_film_inventory(title);

-- SELECT * from temp_film_inventory
-- Populate the film_inventory table with data from the DVD rental database, considering both rentals and returns.

SELECT
	temp_film_inventory.film_id,
	temp_film_inventory.title, 
	COUNT(se_inventory.inventory_id) as inventory_count,
	se_rental.rental_id,
	se_rental.return_date
From temp_film_inventory
LEFT JOIN inventory as se_inventory
	ON temp_film_inventory.film_id = se_inventory.film_id
LEFT JOIN rental as se_rental
	ON se_rental.inventory_id = se_inventory.inventory_id
GROUP BY temp_film_inventory.title, temp_film_inventory.film_id, se_rental.rental_id, se_rental.return_date

-- Retrieve the film title with the lowest available inventory count from the film_inventory table.
SELECT 
	temp_film_inventory.title, 
	inventory_count
FROM temp_film_inventory 
ORDER BY inventory_count ASC 
LIMIT 1


-- Third exercise:
-- Create a Temporary Table named store_performance that
-- stores store IDs, revenue, and the average payment amount per rental.

DROP TABLE IF EXISTS temp_store_performance;
CREATE TEMPORARY TABLE temp_store_performance AS 
(
	SELECT 
		se_store.store_id, 
		SUM(se_payment.amount) as revenue, 
		ROUND(SUM(se_payment.amount)/COUNT(se_rental.rental_id), 2) as avg_payment_per_rental
	FROM store as se_store
	INNER JOIN inventory as se_inventory
		ON se_inventory.store_id = se_store.store_id
	INNER JOIN rental as se_rental
		ON se_rental.inventory_id = se_inventory.inventory_id
	INNER JOIN payment as se_payment 
		ON se_payment.rental_id = se_rental.rental_id
	GROUP BY se_store.store_id
);
CREATE INDEX idx_temp_store_performance ON temp_store_performance(store_id);
SELECT * FROM temp_store_performance