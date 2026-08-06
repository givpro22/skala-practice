package com.skala.stock.exception;

import com.skala.stock.dto.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 모든 컨트롤러에서 발생한 예외를 한 곳에서 처리한다.
 *
 * 이 클래스가 없으면 서비스가 던진 예외가 전부 500으로 나가고,
 * 검증 실패 응답에도 어느 필드가 왜 틀렸는지 담기지 않는다.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // ── 요청 본문 검증 실패 → 400 ────────────────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException e, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError fe : e.getBindingResult().getFieldErrors()) {
            fieldErrors.putIfAbsent(fe.getField(), fe.getDefaultMessage());
        }
        return build(HttpStatus.BAD_REQUEST, "입력값이 올바르지 않습니다", request, fieldErrors);
    }

    // ── 경로·쿼리 파라미터 제약 위반 → 400 ───────────────────────
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(
            ConstraintViolationException e, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        e.getConstraintViolations().forEach(v -> {
            String path = v.getPropertyPath().toString();
            String field = path.contains(".") ? path.substring(path.lastIndexOf('.') + 1) : path;
            fieldErrors.putIfAbsent(field, v.getMessage());
        });
        return build(HttpStatus.BAD_REQUEST, "입력값이 올바르지 않습니다", request, fieldErrors);
    }

    // ── 타입 불일치 → 400 ────────────────────────────────────────
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(
            MethodArgumentTypeMismatchException e, HttpServletRequest request) {
        Class<?> required = e.getRequiredType();
        String typeName = (required == null) ? "올바른 타입" : required.getSimpleName();
        return build(HttpStatus.BAD_REQUEST,
                "'" + e.getName() + "' 값이 올바르지 않습니다: " + e.getValue()
                        + " (" + typeName + " 이어야 합니다)", request, null);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleUnreadable(
            HttpMessageNotReadableException e, HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, "요청 본문을 읽을 수 없습니다. JSON 형식을 확인해 주세요", request, null);
    }

    // ── 업무 규칙 위반(잔액·수량 부족) → 400 ─────────────────────
    @ExceptionHandler(BusinessRuleException.class)
    public ResponseEntity<ErrorResponse> handleBusinessRule(
            BusinessRuleException e, HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, e.getMessage(), request, null);
    }

    // ── 자원 없음 → 404 ──────────────────────────────────────────
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(
            ResourceNotFoundException e, HttpServletRequest request) {
        return build(HttpStatus.NOT_FOUND, e.getMessage(), request, null);
    }

    // ── 중복 / 참조 중이라 삭제 불가 → 409 ───────────────────────
    @ExceptionHandler({DuplicateResourceException.class, ResourceInUseException.class})
    public ResponseEntity<ErrorResponse> handleConflict(
            RuntimeException e, HttpServletRequest request) {
        return build(HttpStatus.CONFLICT, e.getMessage(), request, null);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDataIntegrity(
            DataIntegrityViolationException e, HttpServletRequest request) {
        log.warn("무결성 제약 위반: {}", e.getMessage());
        return build(HttpStatus.CONFLICT, "데이터 제약 조건에 위배됩니다", request, null);
    }

    // ── 없는 경로 · 미지원 메서드 → 404 / 405 ────────────────────
    // 아래 catch-all 이 이 예외들까지 잡아 500으로 만들지 않도록 먼저 처리한다.
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErrorResponse> handleNoResource(
            NoResourceFoundException e, HttpServletRequest request) {
        return build(HttpStatus.NOT_FOUND, "존재하지 않는 경로입니다", request, null);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException e, HttpServletRequest request) {
        return build(HttpStatus.METHOD_NOT_ALLOWED,
                e.getMethod() + " 메서드는 이 경로에서 지원하지 않습니다", request, null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(
            Exception e, HttpServletRequest request) {
        log.error("처리하지 못한 예외", e);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "서버 오류가 발생했습니다", request, null);
    }

    private ResponseEntity<ErrorResponse> build(HttpStatus status, String message,
                                                HttpServletRequest request,
                                                Map<String, String> fieldErrors) {
        return ResponseEntity.status(status).body(ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(status.value())
                .error(status.getReasonPhrase())
                .message(message)
                .path(request.getRequestURI())
                .fieldErrors(fieldErrors)
                .build());
    }
}
