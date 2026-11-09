## VISTAS SQL
Una vista sql es una sentencia o query de sql que guardamos dentro de la base de datos para reutilizarla las veces que queramos. Un ejemplo:
```sql
CREATE OR REPLACE VIEW vw_facturacion_pais AS
SELECT
    pais,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
GROUP BY pais;
```
despues de ejecutar esta query podemos hacer lo siguiente:
```sql
SELECT *
FROM vw_facturacion_pais
ORDER BY facturacion DESC;
```
y el resultado sera:
```
         pais         |        facturacion        
----------------------+---------------------------
 United Kingdom       | 9025222.08400000004808294
 Netherlands          |   285446.3399999999993850
 EIRE                 |   283453.9600000000024124
 Germany              |   228867.1400000000008788
 France               |   209715.1099999999999119
 Australia            |    138521.310000000000062
 Spain                |    61577.1100000000002061
 Switzerland          |    57089.9000000000002192
```
Para comprobar que vistas hemos creado escribe `\dv` dentro de sql:
```
               List of relations
 Schema |        Name         | Type |   Owner   
--------+---------------------+------+-----------
 public | vw_facturacion_pais | view | ecommerce
```
tambien puedes inspeccionar una vista concreta con `\d vw_facturacion_pais`:
```
           View "public.vw_facturacion_pais"
   Column    |  Type   | Collation | Nullable | Default 
-------------+---------+-----------+----------+---------
 pais        | text    |           |          | 
 facturacion | numeric |           |          | 
```