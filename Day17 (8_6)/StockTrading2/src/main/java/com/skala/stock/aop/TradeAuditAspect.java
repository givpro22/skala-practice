package com.skala.stock.aop;

import com.skala.stock.dto.TradeRequestDto;
import com.skala.stock.dto.TransactionDto;
import com.skala.stock.service.TradeAuditRecorder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * 매매가 실행되면 감사 로그를 남긴다.
 *
 * 왜 AOP인가:
 *   "거래를 기록한다"는 요구는 매매 로직 자체와 별개다.
 *   executeTrade() 안에 감사 코드를 넣으면 잔액 계산·포트폴리오 갱신 같은
 *   본래 관심사와 섞인다. 여기로 분리하면 매매 로직은 매매만 다루고,
 *   감사 정책이 바뀌어도 이 클래스만 고치면 된다.
 *
 * @Order(0):
 *   트랜잭션 어드바이저(기본 LOWEST_PRECEDENCE)보다 바깥에 두어,
 *   거래 트랜잭션이 커밋·롤백된 뒤에 감사 로그가 기록되도록 한다.
 *   실제 저장은 TradeAuditRecorder 가 REQUIRES_NEW 로 처리한다.
 */
@Slf4j
@Aspect
@Component
@Order(0)
@RequiredArgsConstructor
public class TradeAuditAspect {

    private final TradeAuditRecorder auditRecorder;

    /** 매매 성공 시 */
    @AfterReturning(
            pointcut = "execution(* com.skala.stock.service.TransactionService.executeTrade(..)) && args(request)",
            returning = "result",
            argNames = "request,result")
    public void logSuccess(TradeRequestDto request, TransactionDto result) {
        String message = "거래 성공 — " + result.getType()
                + " " + result.getStockCode()
                + " " + result.getQuantity() + "주"
                + " / 체결가 " + result.getPrice()
                + " / 총액 " + result.getTotalAmount();

        log.info("[AOP] {}", message);
        auditRecorder.record(request.getUserId(), request.getStockId(), request.getType(), message);
    }

    /** 매매 실패 시 — 실패 사유를 그대로 남긴다 */
    @AfterThrowing(
            pointcut = "execution(* com.skala.stock.service.TransactionService.executeTrade(..)) && args(request)",
            throwing = "ex",
            argNames = "request,ex")
    public void logFailure(TradeRequestDto request, Throwable ex) {
        String message = "거래 실패 — " + ex.getMessage();

        log.warn("[AOP] {}", message);
        auditRecorder.record(request.getUserId(), request.getStockId(), request.getType(), message);
    }
}
