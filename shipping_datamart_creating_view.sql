/*
 Создайте представление shipping_datamart на основании готовых таблиц для аналитики и включите в него:
shippingid
vendorid
transfer_type — тип доставки из таблицы shipping_transfer
full_day_at_shipping — количество полных дней,
 в течение которых длилась доставка. Высчитывается как:shipping_end_fact_datetime-shipping_start_fact_datetime.
is_delay — статус, показывающий просрочена ли доставка. 
	Высчитывается как:shipping_end_fact_datetime >> shipping_plan_datetime ? 1 ; 0
is_shipping_finish — статус, показывающий, что доставка завершена. Если финальный status = finished ? 1; 0
delay_day_at_shipping — количество дней, на которые была просрочена доставка. Высчитыается как: shipping_end_fact_datetime >> shipping_end_plan_datetime ? shipping_end_fact_datetime -? shipping_plan_datetime ; 0).
payment_amount — сумма платежа пользователя
vat — итоговый налог на доставку. Высчитывается как: payment_amount *? ( shipping_country_base_rate ++ agreement_rate ++ shipping_transfer_rate) .
profit — итоговый доход компании с доставки. Высчитывается как: payment_amount*? agreement_commission.
Подсказки:
Чтобы получить разницу между датами, удобно использовать функцию age() . 
Для получения целых дней можно использовать функцию date_part(’day’ , ... ) .
При построении витрины нужно соединить ранее созданные таблицы. 
Вы уже создали внешние ключи в справочниках, и здесь можно заметить, чем они удобны.
 Если использовать JOIN трёх справочников: shipping_transfer , shipping_country_rates и shipping_agreement — 
 к таблице с внешними ключами shipping_info, то разные идентификаторы внешних ключей могут автоматически подсвечивать возможные связи.
 */
--проверка
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from (
select 
	si.shippingid
	, si.vendorid
	, st.transfer_type 
	, date_part('day', age(ss.shipping_end_fact_datetime
			, ss.shipping_start_fact_datetime))::int as full_day_at_shipping
	, case when ss.shipping_end_fact_datetime > si.shipping_plan_datetime then 1 
		else 0 end as is_delay
	, case when ss.status = 'finished' then 1 
		else 0 end as is_shipping_finish
	, case when ss.shipping_end_fact_datetime > si.shipping_plan_datetime 
		then date_part('day', age(ss.shipping_end_fact_datetime
			, si.shipping_plan_datetime ))::int
		else 0 end as delay_day_at_shipping
	, si.payment_amount 
	, (si.payment_amount*(st.shipping_transfer_rate + sa.agreement_rate + scr.shipping_country_base_rate)) as vat
	, (si.payment_amount*sa.agreement_commission) as profit
	--
from public.shipping_info si 
	join public.shipping_transfer st on si.transfer_type_id = st.id 
	join public.shipping_status ss on si.shippingid = ss.shippingid 
	join public.shipping_agreement sa on si.agreementid = sa.agreementid 
	join public.shipping_country_rates scr on si.shipping_country_id = scr.id 
) t;

--представление
create or replace view public.shipping_datamart as
--
select 
	si.shippingid
	, si.vendorid
	, st.transfer_type 
	, date_part('day', age(ss.shipping_end_fact_datetime
			, ss.shipping_start_fact_datetime))::int as full_day_at_shipping
	, case when ss.shipping_end_fact_datetime > si.shipping_plan_datetime then 1 
		else 0 end as is_delay
	, case when ss.status = 'finished' then 1 
		else 0 end as is_shipping_finish
	, case when ss.shipping_end_fact_datetime > si.shipping_plan_datetime 
		then date_part('day', age(ss.shipping_end_fact_datetime
			, si.shipping_plan_datetime ))::int
		else 0 end as delay_day_at_shipping
	, si.payment_amount 
	, (si.payment_amount*(st.shipping_transfer_rate + sa.agreement_rate + scr.shipping_country_base_rate)) as vat
	, (si.payment_amount*sa.agreement_commission) as profit
	--
from public.shipping_info si 
	join public.shipping_transfer st on si.transfer_type_id = st.id 
	join public.shipping_status ss on si.shippingid = ss.shippingid 
	join public.shipping_agreement sa on si.agreementid = sa.agreementid 
	join public.shipping_country_rates scr on si.shipping_country_id = scr.id;

--что получилось в итоге
select * 
from public.shipping_datamart
order by shippingid;

----проверка
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from public.shipping_datamart;