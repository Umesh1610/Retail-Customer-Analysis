use retail;
-------Overview of DATA
SELECT Count(DISTINCT order_id)      AS transactions,
       Count(DISTINCT household_key) AS households,
       Sum(sales_value)              AS sales,
       Sum(retail_dsec)              AS discount,
       Sum(CASE
             WHEN coupon_disc < 0 THEN coupon_disc
           end)                      AS coupons,
       Sum(coupon_disc)              AS coupons,
       Sum(quantity)                 AS quantity,
       Count(DISTINCT day)           AS days,
       Count(DISTINCT week_no)       AS weeks
FROM   transactions_1; 
---------------------------------------
-- Week  sales/discount
SELECT week_no,
       Sum(sales_value)                                                AS sales,
       Sum(retail_dsec)                                                AS discount,
       Abs(Sum(retail_dsec)) / ( Sum(sales_value + Abs(retail_dsec)) ) AS perct_disc,
       Count(DISTINCT order_id)                                        AS transactions,
       Count(DISTINCT household_key)                                   AS household
FROM   transactions_1
GROUP  BY 1 

--------------------------------------
---- day sale/discount
SELECT day,
       Sum(sales_value)                                                AS sales,
       Sum(retail_dsec)                                                AS discount,
       Abs(Sum(retail_dsec)) / ( Sum(sales_value + Abs(retail_dsec)) ) AS perct_disc,
       Count(DISTINCT order_id)                                        AS transactions,
       Count(DISTINCT household_key)                                   AS household
FROM   transactions_1
GROUP  BY 1
ORDER  BY 1; 
-----------------------------------
---TIME level analysis
SELECT trans_time,
       Sum(sales_value)                                                AS sales,
       Sum(retail_dsec)                                                AS discount,
       Abs(Sum(retail_dsec)) / ( Sum(sales_value + Abs(retail_dsec)) ) AS perct_disc,
       Count(DISTINCT order_id)                                        AS transactions,
       Count(DISTINCT household_key)                                   AS household
FROM   transactions_1
GROUP  BY 1 


------ Age wise analysis
SELECT h.age_desc,
       Count(DISTINCT t.household_key) AS t_hk,
       Count(DISTINCT order_id)        AS transaction,
       Sum(sales_value)                AS sales,
       Sum(retail_dsec)                AS discount,
       Count(DISTINCT CASE
                        WHEN retail_dsec < 0 THEN order_id
                      end)             AS Discount_bills,
       Count(DISTINCT CASE
                        WHEN coupon_disc != 0 THEN order_id
                      end)             AS coupon_bills
FROM   transactions_1 t
       LEFT JOIN hh_demographic h
              ON h.household_key = t.household_key
GROUP  BY 1
ORDER  BY 1; 
-------------------
------- income wise analysis
SELECT h.income_desc,
       Count(DISTINCT t.household_key) AS t_hk,
       Count(DISTINCT order_id)        AS transaction,
       Sum(sales_value)                AS sales,
       Sum(retail_dsec)                AS discount,
       Count(DISTINCT CASE
                        WHEN retail_dsec < 0 THEN order_id
                      end)             AS Discount_bills,
       Count(DISTINCT CASE
                        WHEN coupon_disc != 0 THEN order_id
                      end)             AS coupon_bills
FROM   transactions_1 t
       LEFT JOIN hh_demographic h
              ON h.household_key = t.household_key
GROUP  BY 1;

-------------------------------------------------------------------------
---------Coupon using vs non using
WITH baskets
     AS (SELECT order_id,
                household_key,
                Sum(sales_value)       AS sales,
                Sum(coupon_disc)       AS coupon_disc,
                Sum(coupon_match_disc) AS COUPON_MATCH_DISC
         FROM   transactions_1
         GROUP  BY 1,
                   2)
SELECT CASE
         WHEN coupon_disc != 0 THEN 'Coupon Bills'
         ELSE 'No Coupon'
       END                           coupon_bills,
       Count(DISTINCT order_id)      AS transactions,
       Count(DISTINCT household_key) AS households,
       Avg(sales)                    AS sales_mean,
       Avg(coupon_disc)              AS coupon_disc
FROM   baskets
GROUP  BY 1; 
----------------------------------------------------------------------------
----------------------------------------------------
 ------ sale brackets ntile
WITH baskets
     AS (SELECT *,
                Ntile(4)
                  OVER(
                    ORDER BY sales) AS ntile_1
         FROM   (SELECT order_id,
                        household_key,
                        Sum(sales_value)       AS sales,
                        Sum(coupon_disc)       AS coupon_disc,
                        Sum(coupon_match_disc) AS COUPON_MATCH_DISC
                 FROM   transactions_1
                 GROUP  BY 1,
                           2) AS a)
SELECT ntile_1,
       Max(sales)                    AS max_sales,
       Min(sales)                    AS min_sales,
       Count(DISTINCT CASE
                        WHEN coupon_disc != 0 THEN order_id
                      END)           AS coupon_bills,
       Count(DISTINCT order_id)      AS transactions,
       Count(DISTINCT household_key) AS households,
       Avg(sales)                    AS sales_mean,
       Avg(CASE
             WHEN coupon_disc < 0 THEN coupon_disc
           END)                      AS coupon_disc
FROM   baskets
GROUP  BY 1; 
------------------------------------------------------------------
-------Product overview
SELECT department,
       commodity_desc,
       Sum(transactions)            AS transactions,
       Sum(households)              AS households,
       Sum(sales)                   AS sales,
       Sum(sales)
         OVER (
           partition BY department) AS department_sales,
       Sum(discount)                AS discount,
       Sum(coupons)                 AS coupons,
       Sum(quantity)                AS quantity
FROM   (SELECT department,
               commodity_desc,
               Count(DISTINCT order_id)      AS transactions,
               Count(DISTINCT household_key) AS households,
               Sum(sales_value)              AS sales,
               Sum(retail_dsec)              AS discount,
               Sum(coupon_disc)              AS coupons,
               Sum(quantity)                 AS quantity
        FROM   transactions_1 h
               JOIN product p
                 ON h.product_id = p.product_id
        GROUP  BY 1,
                  2) h
GROUP  BY 1,
          2
ORDER  BY 1,
          2; 
---------------------------------------------------
----
--- campaign info
SELECT description,
       Count(campaign_key) AS campaigns
FROM   campaign_desc
GROUP  BY 1; 
--------household targetted
SELECT campaign_id,
       Count(household_key_1) AS households
FROM   campaign_table
GROUP  BY 1; 
------campaign wise duration
SELECT campaign_key,
       ( end_day - start_day ) AS duration
FROM   campaign_desc; 
--avg campaign duration
SELECT Avg(end_day - start_day) AS avg_campign_duration
FROM   campaign_desc; 
---campaign type wise campaign duration
SELECT description,
       Count(campaign_key)      AS campaigns,
       Avg(end_day - start_day) AS avg_campign_duration
FROM   campaign_desc
GROUP  BY 1
ORDER  BY 1; 


-----------campaign - household participation
SELECT campaigns_participated,
       Count(DISTINCT t.household_key) AS households_participated
FROM   (SELECT household_key_1,
               Count(DISTINCT campaign_id) AS campaigns_participated
        FROM   campaign_table
        GROUP  BY 1
        ORDER  BY 1) AS a
       RIGHT JOIN (SELECT DISTINCT household_key
                   FROM   transactions_1) t
               ON t.household_key = a.household_key_1
GROUP  BY 1
ORDER  BY 1; 
-------coupon redemption basis campaign
SELECT c.campaign_id2,
       cd.description,
       Count(DISTINCT c.coupon_issuance_id) AS issuance,
       Count(DISTINCT d.redemption_id)      AS redemption
FROM   coupon c
       LEFT JOIN coupon_redemp d
              ON c.coupon_issuance_id = d.issuance_id
       JOIN campaign_desc cd
         ON cd.campaign_key = c.campaign_id2
GROUP  BY 1,
          2; 
-----campaign type wise redemption
SELECT cd.description,
       Count(DISTINCT c.coupon_issuance_id) AS issuance,
       Count(DISTINCT d.redemption_id)      AS redemption
FROM   coupon c
       LEFT JOIN coupon_redemp d
              ON c.coupon_issuance_id = d.issuance_id
       JOIN campaign_desc cd
         ON cd.campaign_key = c.campaign_id2
GROUP  BY 1; 
---product to coupon redemption
SELECT p.department,
       p.commodity_desc,
       Count(DISTINCT c.coupon_issuance_id) AS issuance,
       Count(DISTINCT d.redemption_id)      AS redemption
FROM   coupon c
       LEFT JOIN coupon_redemp d
              ON c.coupon_issuance_id = d.issuance_id
       JOIN campaign_desc cd
         ON cd.campaign_key = c.campaign_id2
       JOIN product p
         ON c.product_id_1 = p.product_id
GROUP  BY 1,
          2;

-----age wise coupon redemption
SELECT h.age_desc,
       Count(cd.redemption_id) AS redemptions
FROM   coupon_redemp cd
       LEFT JOIN hh_demographic h
              ON h.household_key = cd.household_key
GROUP  BY 1
ORDER  BY 1; 
-----------------income wise coupon redemption
SELECT h.income_desc,
       Count(cd.redemption_id) AS redemptions
FROM   coupon_redemp cd
       LEFT JOIN hh_demographic h
              ON h.household_key = cd.household_key
GROUP  BY 1
ORDER  BY 1; 