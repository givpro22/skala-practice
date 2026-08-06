package com.skala.stock.exception;

/**
 * 요청한 자원을 찾지 못했을 때 발생합니다. (HTTP 404)
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public static ResourceNotFoundException of(String resource, Object id) {
        return new ResourceNotFoundException(resource + "을(를) 찾을 수 없습니다: " + id);
    }
}
