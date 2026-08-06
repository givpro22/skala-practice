package com.skala.stock.exception;

/**
 * 형식은 맞지만 업무 규칙을 위반한 요청일 때 발생합니다. (HTTP 400)
 * 예) 잔액 부족, 보유 수량 부족
 */
public class BusinessRuleException extends RuntimeException {

    public BusinessRuleException(String message) {
        super(message);
    }
}
