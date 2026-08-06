package com.skala.stock.exception;

/** 형식은 맞지만 업무 규칙을 위반했을 때 (HTTP 400) — 잔액 부족, 수량 부족 등 */
public class BusinessRuleException extends RuntimeException {
    public BusinessRuleException(String message) { super(message); }
}
