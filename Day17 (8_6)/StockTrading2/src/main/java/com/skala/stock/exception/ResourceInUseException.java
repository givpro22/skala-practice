package com.skala.stock.exception;

/**
 * 다른 자원이 참조 중이라 삭제할 수 없을 때 (HTTP 409)
 *
 * portfolios · transactions 가 user_id / stock_id 를 NOT NULL 외래키로
 * 참조하므로, 참조가 남은 채 삭제하면 무결성 제약 위반으로 500이 난다.
 */
public class ResourceInUseException extends RuntimeException {
    public ResourceInUseException(String message) { super(message); }
}
