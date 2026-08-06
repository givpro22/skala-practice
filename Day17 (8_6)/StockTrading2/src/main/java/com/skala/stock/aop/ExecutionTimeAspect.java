package com.skala.stock.aop;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

/**
 * 서비스 계층 메서드의 실행 시간을 측정해 로그로 남긴다.
 *
 * 왜 AOP인가:
 *   실행 시간 측정은 모든 서비스 메서드에 필요하지만 업무 로직과는 무관하다.
 *   메서드마다 System.currentTimeMillis()를 넣으면 본래 코드가 묻히고,
 *   빠뜨린 메서드가 생긴다. 한 곳에 모아 두면 서비스 코드는 깨끗해지고
 *   적용 범위도 포인트컷 한 줄로 관리된다.
 *
 * 느린 호출(100ms 이상)은 WARN으로 올려 눈에 띄게 한다.
 */
@Slf4j
@Aspect
@Component
public class ExecutionTimeAspect {

    private static final long SLOW_THRESHOLD_MS = 100;

    /** com.skala.stock.service 패키지의 모든 public 메서드 */
    @Pointcut("execution(public * com.skala.stock.service..*(..))")
    public void serviceMethods() {
    }

    @Around("serviceMethods()")
    public Object measure(ProceedingJoinPoint joinPoint) throws Throwable {
        String target = joinPoint.getSignature().getDeclaringType().getSimpleName()
                + "." + joinPoint.getSignature().getName();
        long start = System.nanoTime();

        try {
            return joinPoint.proceed();
        } finally {
            long elapsedMs = (System.nanoTime() - start) / 1_000_000;
            if (elapsedMs >= SLOW_THRESHOLD_MS) {
                log.warn("[AOP] {} 실행 {}ms — 느림", target, elapsedMs);
            } else {
                log.info("[AOP] {} 실행 {}ms", target, elapsedMs);
            }
        }
    }
}
