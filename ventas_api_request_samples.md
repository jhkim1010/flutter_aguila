# Ventas API GET 요청 샘플

## 기본 엔드포인트
```
GET /api/reporte/ventas
```

## 1. unit='vcode' (개별 vcode 표시)

### 요청 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=vcode&fecha_inicio=2025-12-01&fecha_fin=2025-12-31
```

### 전체 파라미터 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=vcode&fecha_inicio=2025-12-01&fecha_fin=2025-12-31&filtering_word=cliente&sucursal=1
```

### cURL 예시
```bash
curl -X GET "http://localhost:3000/api/reporte/ventas?current_date=2025-12-08&unit=vcode&fecha_inicio=2025-12-01&fecha_fin=2025-12-31" \
  -H "Content-Type: application/json"
```

### 설명
- `unit=vcode`: 각 vcode를 개별적으로 표시
- `current_date`: 필수 파라미터 (기준 날짜)
- `fecha_inicio`, `fecha_fin`: 날짜 범위 필터 (선택)
- `filtering_word`: 검색어 (선택, clientenombre에서 검색)
- `sucursal`: 지점 필터 (선택)

---

## 2. unit='day' (일별 그룹화)

### 요청 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=day&fecha_inicio=2025-12-01&fecha_fin=2025-12-31
```

### 전체 파라미터 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=day&fecha_inicio=2025-12-01&fecha_fin=2025-12-31&sucursal=1
```

### cURL 예시
```bash
curl -X GET "http://localhost:3000/api/reporte/ventas?current_date=2025-12-08&unit=day&fecha_inicio=2025-12-01&fecha_fin=2025-12-31" \
  -H "Content-Type: application/json"
```

### 설명
- `unit=day`: 날짜별로 그룹화하여 합산
- 각 레코드의 `fecha` 필드는 `"YYYY-MM-DD"` 형식 (예: `"2025-12-08"`)
- 같은 날짜의 모든 거래가 하나의 레코드로 합산됨

---

## 3. unit='month' (월별 그룹화)

### 요청 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=month&fecha_inicio=2025-01-01&fecha_fin=2025-12-31
```

### 전체 파라미터 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=month&fecha_inicio=2025-01-01&fecha_fin=2025-12-31&sucursal=2
```

### cURL 예시
```bash
curl -X GET "http://localhost:3000/api/reporte/ventas?current_date=2025-12-08&unit=month&fecha_inicio=2025-01-01&fecha_fin=2025-12-31" \
  -H "Content-Type: application/json"
```

### 설명
- `unit=month`: 월별로 그룹화하여 합산
- 각 레코드의 `fecha` 필드는 `"YYYY-MM"` 형식 (예: `"2025-12"`)
- 같은 월의 모든 거래가 하나의 레코드로 합산됨

---

## 4. unit='year' (연도별 그룹화)

### 요청 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=year&fecha_inicio=2020-01-01&fecha_fin=2025-12-31
```

### 전체 파라미터 예시
```
GET /api/reporte/ventas?current_date=2025-12-08&unit=year&fecha_inicio=2020-01-01&fecha_fin=2025-12-31&sucursal=1
```

### cURL 예시
```bash
curl -X GET "http://localhost:3000/api/reporte/ventas?current_date=2025-12-08&unit=year&fecha_inicio=2020-01-01&fecha_fin=2025-12-31" \
  -H "Content-Type: application/json"
```

### 설명
- `unit=year`: 연도별로 그룹화하여 합산
- 각 레코드의 `fecha` 필드는 `"YYYY"` 형식 (예: `"2025"`)
- 같은 연도의 모든 거래가 하나의 레코드로 합산됨

---

## 공통 파라미터

### 필수 파라미터
- `current_date`: 기준 날짜 (YYYY-MM-DD 형식)

### 선택 파라미터
- `unit`: 그룹화 단위 (`vcode`, `day`, `month`, `year`)
  - 기본값: `vcode` (또는 생략 시)
- `fecha_inicio`: 시작 날짜 (YYYY-MM-DD 형식)
- `fecha_fin`: 종료 날짜 (YYYY-MM-DD 형식)
- `filtering_word`: 검색어 (clientenombre 필드에서 검색)
- `sucursal`: 지점 필터 (숫자)

---

## 응답 형식

모든 unit 값에 대해 동일한 응답 구조를 사용합니다:

```json
{
  "success": true,
  "fecha": "2025-12-08",  // 또는 "2025-12" (month), "2025" (year)
  "total": 1500000,
  "count": 50,
  "hasMore": false,
  "next_vcode_id": null,
  "data": [
    {
      "id": 12300,
      "vcode": "12300",
      "hora": "10:30:00",
      "tpago": 50000,
      "cntropas": 1,
      "clientenombre": "Cliente ABC",
      "tefectivo": 30000,
      "tcredito": 20000,
      "tbanco": 0,
      "treservado": 0,
      "tfavor": 0,
      "vendedor": "VEND001",
      "tipo": 1,
      "dni": "12345678",
      "resiva": 1,
      "casoesp": null,
      "nencargado": null,
      "cretmp": 0,
      "fecha": "2025-12-08",  // unit에 따라 형식이 다름
      "sucursal": 2,
      "ntiqrepetir": null,
      "vcode_id": 12300,
      "b_mercadopago": false,
      "d_num_caja": 1,
      "d_num_terminal": 1
    }
  ]
}
```

### unit별 fecha 필드 형식
- `vcode`: `"YYYY-MM-DD"` (예: `"2025-12-08"`)
- `day`: `"YYYY-MM-DD"` (예: `"2025-12-08"`)
- `month`: `"YYYY-MM"` (예: `"2025-12"`)
- `year`: `"YYYY"` (예: `"2025"`)

### unit별 null 필드
- `vcode`: 모든 필드가 채워짐
- `day`, `month`, `year`: 개별 거래 정보는 null
  - `id`, `vcode`, `hora`, `clientenombre`, `vendedor` 등은 null
  - 집계 필드(`tpago`, `cntropas`, `tefectivo` 등)만 값이 있음
