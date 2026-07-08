with rfm as (
             select CustomerID
                    ,DATEDIFF(DAY,max(soh.OrderDate),(select DATEADD(DAY,1,max(OrderDate)) from Sales.SalesOrderHeader)) as [recency]
                    ,COUNT(distinct(soh.SalesOrderID)) as [frequency]
                    ,SUM(sod.LineTotal) as [monetary]
             from Sales.SalesOrderHeader as soh inner join Sales.SalesOrderDetail as sod on (soh.SalesOrderID = sod.SalesOrderID)
             group by soh.CustomerID
                   ),
RFMscores as (
              select customerid
                     ,recency
                     ,NTILE(5) over(order by recency desc) as [Rscore]
                     ,frequency
                     ,case when frequency >= 10 then 5
                           when frequency >= 7 then 4
                           when frequency >= 5 then 3
                           when frequency >= 3 then 2 
                           when frequency >= 1 then 1 
                           else 0 
                      end as [Fscore]
                     ,monetary
                     ,NTILE(5) over(order by monetary asc) as [Mscore]
              from rfm
                ),
segment as (
             select customerid
                    ,recency
                    ,rscore
                    ,frequency
                    ,fscore
                    ,monetary
                    ,mscore
                    ,case when rscore >= 4 and fscore >= 4 and mscore >= 4 then 'VIP'
                          when rscore >= 3 and fscore >= 4 then 'Loyal Customers'
                          when rscore >= 4 and fscore <= 2  then 'New Customers'
                          when rscore <= 2 and fscore >= 3 then 'At risk'
                          when rscore <= 2 and fscore <= 2 then 'Lost'
                          else 'Potential'
                    end as [Customers_segment]
             from RFMscores
               ),
count_segment as (
                   select Customers_segment
                          ,COUNT(*) as [total_customers]
                   from segment
                   group by Customers_segment
                    )

select  Customers_segment
       ,total_customers
       ,ROUND(CAST([total_customers] AS FLOAT) / (select SUM([total_customers]) from count_segment) * 100, 2) as [Segment_Percentage]
       ,ROUND(CUME_DIST() over(order by [total_customers] asc) * 100, 2) as [Cumulative_Distribution_Pct]
from count_segment 
order by total_customers