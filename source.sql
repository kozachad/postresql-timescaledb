-- TimescaleDB eklentisini oluşturma
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- sensor_data tablosunu oluşturma
CREATE TABLE sensor_data (
    time TIMESTAMPTZ NOT NULL,  -- Zaman damgası, boş olamaz
    temperature DOUBLE PRECISION,  -- Sıcaklık verisi, çift hassasiyetli
    current DOUBLE PRECISION  -- Akım verisi, çift hassasiyetli
);

-- Veri ekleme işlemi
DO $$
DECLARE 
    i INT := 0;
    days INT := 0;
BEGIN
    -- 1000 gün için döngü
    WHILE days < 1000 LOOP
        -- Her gün için 1000 dakika veri ekleme döngüsü
        WHILE i < 1000 LOOP
            INSERT INTO sensor_data (time, temperature, current)
            VALUES (NOW() - (days || ' days')::INTERVAL - (i || ' minutes')::INTERVAL, random() * 40, random() * 10);
            i := i + 1;
        END LOOP;
        i := 0;
        days := days + 1;
    END LOOP;
END $$;

-- sensor_data tablosunu bir hypertable'a dönüştürme
SELECT create_hypertable('sensor_data', 'time', if_not_exists => TRUE, migrate_data => true);

-- BRIN indeks oluşturma
CREATE INDEX brin_sensor_data_time ON sensor_data USING BRIN (time);

-- Sorgu performansını analiz etme
EXPLAIN ANALYZE
SELECT
    time_bucket('1 day', time) AS day,  -- Zamanı günlük aralıklara ayırma
    COUNT(*) AS count,  -- Veri sayısı
    AVG(temperature) AS avg_temperature,  -- Ortalama sıcaklık
    AVG(current) AS avg_current,  -- Ortalama akım
    MAX(temperature) AS max_temperature,  -- Maksimum sıcaklık
    MIN(temperature) AS min_temperature,  -- Minimum sıcaklık
    MAX(current) AS max_current,  -- Maksimum akım
    MIN(current) AS min_current  -- Minimum akım
FROM sensor_data
GROUP BY day  -- Gün bazında gruplama
ORDER BY day;  -- Gün bazında sıralama

-- Verileri sorgulama
SELECT
    time_bucket('1 day', time) AS day,  -- Zamanı günlük aralıklara ayırma
    COUNT(*) AS count,  -- Veri sayısı
    AVG(temperature) AS avg_temperature,  -- Ortalama sıcaklık
    AVG(current) AS avg_current,  -- Ortalama akım
    MAX(temperature) AS max_temperature,  -- Maksimum sıcaklık
    MIN(temperature) AS min_temperature,  -- Minimum sıcaklık
    MAX(current) AS max_current,  -- Maksimum akım
    MIN(current) AS min_current  -- Minimum akım
FROM sensor_data
GROUP BY day  -- Gün bazında gruplama
ORDER BY day;  -- Gün bazında sıralama
