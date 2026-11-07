SELECT pais, COUNT(invoice_no) AS numero_facturas 
    FROM ventas_online_retail 
    GROUP BY pais HAVING COUNT(invoice_no) >= 500 
    ORDER BY numero_facturas DESC;