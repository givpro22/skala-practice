package com.skala.stock.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 모든 오류 응답의 공통 형식입니다.
 * 값이 없는 필드는 JSON에서 아예 빠집니다.
 */
@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {

    private final LocalDateTime timestamp;
    private final int status;
    private final String error;
    private final String message;
    private final String path;

    /** 입력값 검증 실패 시에만 채워집니다. 필드명 → 위반 사유 */
    private final Map<String, String> fieldErrors;
}
