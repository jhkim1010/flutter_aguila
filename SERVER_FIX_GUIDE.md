# ventas_rpt_a_day 함수 수정 가이드

## 문제 상황
PostgreSQL 함수 `ventas_rpt_a_day(date, date)`를 호출할 때 "function does not exist" 에러가 발생합니다.

## 1. 함수 시그니처 확인

먼저 PostgreSQL에서 함수의 실제 시그니처를 확인하세요:

```sql
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'ventas_rpt_a_day';
```

## 2. 가능한 원인

### 원인 1: 함수가 다른 스키마에 있음
- 함수가 `public` 스키마가 아닌 다른 스키마에 있을 수 있습니다.
- 위 쿼리 결과에서 `schema_name`을 확인하세요.

### 원인 2: 함수 시그니처 불일치
함수가 다음 중 하나일 수 있습니다:
- `ventas_rpt_a_day(timestamp, timestamp)`
- `ventas_rpt_a_day(text, text)`
- `ventas_rpt_a_day(date, date)` (현재 호출하는 형식)

### 원인 3: 함수가 다른 데이터베이스에 있음
- `inquieta14` 데이터베이스에 함수가 있는지 확인하세요.

## 3. 서버 측 코드 수정 방법

서버 측 코드에서 함수를 호출하는 부분을 찾아 수정하세요.

### 예시: Node.js/PostgreSQL 코드

#### 현재 코드 (문제가 있는 코드)
```javascript
// date 타입으로 호출
const query = `SELECT * FROM public.ventas_rpt_a_day($1, $2)`;
await client.query(query, [startDate, endDate]);
```

#### 수정 방법 1: 함수 시그니처에 맞게 타입 캐스팅
```javascript
// 만약 함수가 timestamp를 받는다면
const query = `SELECT * FROM public.ventas_rpt_a_day($1::TIMESTAMP, $2::TIMESTAMP)`;
await client.query(query, [startDate, endDate]);

// 만약 함수가 text를 받는다면
const query = `SELECT * FROM public.ventas_rpt_a_day($1::TEXT, $2::TEXT)`;
await client.query(query, [startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]]);
```

#### 수정 방법 2: 스키마 명시
```javascript
// 스키마를 명시적으로 지정
const query = `SELECT * FROM ${schemaName}.ventas_rpt_a_day($1::DATE, $2::DATE)`;
await client.query(query, [startDate, endDate]);
```

#### 수정 방법 3: 함수가 없을 경우 fallback 쿼리 사용 (현재 구현)
```javascript
try {
    // 함수 호출 시도
    const query = `SELECT * FROM public.ventas_rpt_a_day($1::DATE, $2::DATE)`;
    const result = await client.query(query, [startDate, endDate]);
    return result.rows;
} catch (error) {
    if (error.code === '42883') { // function does not exist
        console.log('⚠️ 함수가 존재하지 않아 직접 쿼리로 fallback합니다.');
        // 직접 쿼리로 fallback
        const fallbackQuery = `
            SELECT 
                vcode,
                tpago,
                cntropas,
                clientenombre,
                tefectivo,
                tcredito,
                tbanco,
                treservado,
                tfavor,
                vendedor,
                tipo,
                dni,
                hora,
                fecha,
                resiva,
                casoesp,
                nencargado,
                cretmp,
                sucursal,
                ntiqrepetir,
                b_mercadopago,
                d_num_caja,
                d_num_terminal,
                id
            FROM ventas
            WHERE fecha >= $1::DATE AND fecha <= $2::DATE
        `;
        const result = await client.query(fallbackQuery, [startDate, endDate]);
        return result.rows;
    }
    throw error;
}
```

## 4. 함수 생성 (함수가 없는 경우)

함수가 실제로 존재하지 않는다면, 함수를 생성할 수 있습니다:

```sql
CREATE OR REPLACE FUNCTION public.ventas_rpt_a_day(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    vcode INTEGER,
    tpago VARCHAR,
    cntropas INTEGER,
    clientenombre VARCHAR,
    tefectivo NUMERIC,
    tcredito NUMERIC,
    tbanco NUMERIC,
    treservado NUMERIC,
    tfavor NUMERIC,
    vendedor VARCHAR,
    tipo VARCHAR,
    dni VARCHAR,
    hora TIME,
    fecha DATE,
    resiva NUMERIC,
    casoesp VARCHAR,
    nencargado INTEGER,
    cretmp TIMESTAMP,
    sucursal INTEGER,
    ntiqrepetir INTEGER,
    b_mercadopago BOOLEAN,
    d_num_caja INTEGER,
    d_num_terminal INTEGER,
    id INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.vcode,
        v.tpago,
        v.cntropas,
        v.clientenombre,
        v.tefectivo,
        v.tcredito,
        v.tbanco,
        v.treservado,
        v.tfavor,
        v.vendedor,
        v.tipo,
        v.dni,
        v.hora,
        v.fecha,
        v.resiva,
        v.casoesp,
        v.nencargado,
        v.cretmp,
        v.sucursal,
        v.ntiqrepetir,
        v.b_mercadopago,
        v.d_num_caja,
        v.d_num_terminal,
        v.id
    FROM ventas v
    WHERE v.fecha >= start_date AND v.fecha <= end_date
    ORDER BY v.fecha, v.hora;
END;
$$ LANGUAGE plpgsql;
```

## 5. 테스트

수정 후 다음을 테스트하세요:

1. 함수 시그니처 확인:
```sql
SELECT * FROM public.ventas_rpt_a_day('2025-12-01'::DATE, '2025-12-31'::DATE);
```

2. 서버 API 엔드포인트 테스트:
```bash
curl -X POST http://localhost:3000/api/resumen_del_dia \
  -H "Content-Type: application/json" \
  -H "x-db-name: inquieta14" \
  -H "x-db-user: inquieta" \
  -H "x-db-password: your_password" \
  -d '{"date": "2025-12-17"}'
```

## 6. 클라이언트 측 처리

클라이언트(Flutter) 측에서는 이미 fallback 로직이 구현되어 있어, 함수가 없어도 직접 쿼리로 처리됩니다. 하지만 서버 측에서 함수를 올바르게 호출하면 성능이 향상될 수 있습니다.

## 참고

- PostgreSQL 함수 오류 코드: `42883` = function does not exist
- 함수 시그니처는 대소문자를 구분합니다
- 스키마를 명시하지 않으면 `search_path`에 따라 함수를 찾습니다

