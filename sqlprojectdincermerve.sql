--Question 1 : 
--Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.
SELECT date_trunc('month',order_approved_at)::DATE  payment_month,
COUNT(order_id) order_count
FROM orders_dataset
WHERE order_approved_at IS NOT NULL
GROUP BY 1
ORDER BY 1
LIMIT 100

-- tabloda bazı aylarda genel bir artış söz konusu. ocak ayından agustos ayına kadar bir artış var.
--ocak ayından şubat ayına bir artış var. şubat ayında özel bir gün mesela hristiyanların kutladıgı karnavaldan dolayı siparişler artmış olabilir.
--mayıs ayında ilkbaharın gelmesiyle insaların sezonluk mevsim alışverişi yapmasına sebep olmuş olabilir.
-- temmuz ve agustos ayına geldiğimizde ise artış artık yaz mevsiminin gelmiş olması ve insanların tatile kıyafetlere vs. para harcamasına sebep olmuş olabilir.
-- eylül ekimdeki düşüşün sebebi ise yaz sezonunun bitiyo olması olabilir.
-- kasım ayındaki artış black friday etkisi olabilir.

--Question 2 : 
--Aylık olarak order status kırılımında order sayılarını inceleyiniz. Sorgu sonucunda çıkan outputu excel ile görselleştiriniz. Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı? Veriyi inceleyerek yorumlayınız.
select
	date_part('month',order_approved_at) as ay,
    sum(case when order_status = 'delivered' then 1 else 0 end) as delivered,-- teslim edilen
    sum(case when order_status = 'invoiced'  then 1 else 0 end) as invoiced, -- faturalı
    sum(case when order_status = 'shipped'   then 1 else 0 end) as shipped, -- gönderildi
	sum(case when order_status = 'unavailable' then 1 else 0 end) as unavailable, -- kullanım dışı
	sum(case when order_status = 'processing' then 1 else 0 end) as processing, -- işlemde
	sum(case when order_status = ' canceled'   then 1 else 0 end) as canceled -- iptal edilmiş
from
   orders_dataset
where order_approved_at is not null
group by 
	date_part('month',order_approved_at)
order by
	ay
;
-- mayıs ayında bi yükselme var. bir trend ortaya çıktıgından insanlar daha fazla alışveriş yapmış olabilir. yaz döneminde özellikle agustosta mevsimsel geçişten kaynaklı bir yükselme var.
--ya da indiirim olmuş olabilir.  
-- mart ayında gönderilmiş ama teslim edilmemiş sipariş sayısında bir artma söz konusu. teslimat sorunları veya müşteri yoklugu olabilir.


--Question 3 : 
--Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir? Örneğin yılbaşı, sevgililer günü…
WITH february_orders AS (
    SELECT
        p.product_category_name,
        COUNT(o.order_id) AS o rder_count
    FROM
        products_dataset p
        JOIN items_dataset i ON p.product_id = i.product_id
        JOIN orders_dataset o ON i.order_id = o.order_id
	 GROUP BY
        p.product_category_name
 )
SELECT
    order_count,
	product_category_name,
	EXTRACT(month FROM '2018-02-14 12:00:00'::timestamp)
FROM
    february_orders
ORDER BY
    order_count DESC;	
-- şubat ayında daha çok insanlar kişisel bakımlarına güzellik, spor vs gibi önem veriyor. satıcılara bu verilere bakarak daha çok bu kategorilerde ürürnler üretmesini önerebiliriz.
	
	
	
--Question 4 : 
--Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz. Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız
SELECT
    EXTRACT(DOW FROM o.order_approved_at) AS day_of_week,
    COUNT(o.order_id) AS order_count
FROM
    orders_dataset o
	where order_approved_at is not null
GROUP BY
    day_of_week
ORDER BY
    day_of_week;
	
--haftanın başında siparişler oldukça düşük. demek ki insanlar haftaya  başladıklarında sipariş etmeyi pek tercih etmiyolar.
-- haftanın ortasına dogru siparişler artıyo. sonuna dogru tekrar azalıyo. en yüksek sipariş değeri haftanın ortasında. satıcılara
--haftanın ortasında daha fazla personel tahsis edilmesi önerilebilir.özel kampanyalar yapılabilir.
----------------------------------------------------------
SELECT
    EXTRACT(DAY FROM o.order_approved_at) AS day_of_month,
    COUNT(o.order_id) AS order_count
FROM
    orders_dataset o
	where order_approved_at is not null
GROUP BY
    day_of_month
ORDER BY
    day_of_month;

--Case 2 : Müşteri Analizi 
--Question 1 : 
--Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 
WITH cityorder AS (
    SELECT
		c.customer_unique_id,
        c.customer_city,
        COUNT(o.order_id) AS order_count,
        RANK() OVER (PARTITION BY c.customer_unique_id ORDER BY COUNT(o.order_id) DESC) AS city_rank
    FROM
        customers_dataset c
        JOIN orders_dataset o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_city, c.customer_unique_id
)
SELECT
    customer_city,
	customer_unique_id
FROM
    cityorder
WHERE
    city_rank = 1;
	
--Case 3: Satıcı Analizi
--Question 1 : 
--Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız
WITH deliverytimes AS (
    SELECT
        i.seller_id,
        AVG(EXTRACT(DAY FROM (od.order_delivered_customer_date - od.order_purchase_timestamp))) AS average_delivery_time_minutes
    FROM
        items_dataset i
        JOIN orders_dataset od ON i.order_id = od.order_id
    GROUP BY
        i.seller_id
)
SELECT
    seller_id,
    average_delivery_time_minutes
FROM
    deliverytimes
ORDER BY
    average_delivery_time_minutes
LIMIT 5;
--BAZI SATICILARIN ÇOK AZ SİPARİŞLERİ VAR. ZAMANINDA TESLİM ETMESİ ONU DAHA HIZLI VE İYİ BİR SATICI YAPAR MI TARTIŞILIR. 
-- bu veriler satıcıların hızlı teslimat yapma konusundaki performanslarını değerlendirmelerine ve gerektiğinde iyileştirme yapmalarını sağlar.

--Question 2 : 
--Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 
WITH pcategory as(
select
	s.seller_id,
	p.product_category_name,
	count(p.product_category_name) as product,
	count(o.order_id)
	from sellers_dataset s
	join items_dataset id on s.seller_id = id.seller_id
	join products_dataset p on id.product_id = p.product_id
	join orders_dataset o on o.order_id = id.order_id
	group by 
	1, 2
)
select * from
pcategory
order by product desc
;bu sorgu, her bir ürün kategorisi için satıcıların sattığı ürün sayılarını ve bu ürün kategorileri için alınan toplam sipariş sayılarını hesaplar ve ürün sayısına göre sıralar. Bu, hangi ürün kategorilerinin en çok satıldığını ve sipariş aldığını anlamak için kullanışlı bir analiz sağlar.
--

--Case 4 : Payment Analizi
--Question 1 : 
--Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.
WITH paymentinstallments AS (
    SELECT
        c.customer_state,
        p.payment_installments
    FROM
        payments_dataset p
        JOIN orders_dataset o ON p.order_id = o.order_id
        JOIN customers_dataset c ON o.customer_id = c.customer_id
)
SELECT
    customer_state,
    AVG(payment_installments) AS average_installments
FROM
    paymentinstallments
GROUP BY
    customer_state
ORDER BY
    average_installments DESC;
--iş stratejilerinizi geliştirmek için kullanabilirsiniz. Örneğin, taksit seçeneklerini tanıtarak veya ödeme kolaylıkları sunarak daha fazla müşteriyi çekmeyi hedefleyebilirsiniz.
--Bu analiz, işletmenizin müşteri davranışını anlamanıza ve pazarlama stratejilerinizi şekillendirmenize yardımcı olabilir. Hangi bölgelerde ödeme yaparken taksit sayısı fazla kullanılıyorsa, bu bilgilerle daha etkili bir pazarlama stratejisi oluşturabilirsiniz.
-- sebebi ekonomik koşullar olabilir. alışveriş alışkanlıkları olabilir. taksit imkanının daha güvenilir hissettirmesi olabilir.
--Question 2 : 
--Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.
WITH successfulpayments AS (
    SELECT
        p.payment_type,
        o.order_status,
        o.order_id,
        p.payment_value
    FROM
        payments_dataset p
        JOIN orders_dataset o ON p.order_id = o.order_id
    WHERE
        o.order_status = 'delivered'
)
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS successful_order_count,
    SUM(payment_value) AS total_successful_payment_amount
FROM
    successfulpayments
GROUP BY
    payment_type
ORDER BY
    COUNT(DISTINCT order_id) DESC;
	
	-- kredi kartı daha yaygın bunun sebebi kredi kartının sundugu olanaklar olabilir. taksit seçenegi, nakit para ihtiyacıvs banka kartı en düşük bunun sebebi limit olabilir. büyük harcamalar için banka kartı pek uygun değil.
--Question 3 : 
-- Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?
WITH paymentcategory AS (
    SELECT
        p.order_id,
        p.payment_installments,
        pr.product_category_name
    FROM
        payments_dataset p
        JOIN items_dataset i ON p.order_id = i.order_id
        JOIN products_dataset pr ON i.product_id = pr.product_id
)
SELECT
    product_category_name,
    SUM(CASE WHEN payment_installments = 1 THEN 1 ELSE 0 END) AS single_payment_count,
    SUM(CASE WHEN payment_installments > 1 THEN 1 ELSE 0 END) AS installment_payment_count
FROM
    paymentcategory
GROUP BY
    product_category_name
ORDER BY
    installment_payment_count DESC;
--Ürün kategorileri arasında taksitli ödemelerin daha yaygın olduğu kategorileri tanımlayarak, satıcılar bu kategorilerde taksitli ödeme seçeneklerini vurgulayabilirler. Bu, müşterilerin bu kategorilerde daha fazla alışveriş yapmalarını teşvik edebilir.
--Satıcılar, taksit sayısını artırarak veya farklı taksit seçenekleri sunarak müşterilerin çeşitli tercihlerine cevap verebilirler.
-- bu öneriler satışları artırır ve alışverişi daha cazip gösterir.
--- rfm de sorguda bir çok hatayla karşılaştım. sorguyu yazamadım...











































