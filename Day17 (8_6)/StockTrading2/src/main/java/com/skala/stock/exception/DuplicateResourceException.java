package com.skala.stock.exception;

/** 이미 존재하는 값으로 등록·수정하려 할 때 (HTTP 409) */
public class DuplicateResourceException extends RuntimeException {
    public DuplicateResourceException(String message) { super(message); }
}
