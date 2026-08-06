package com.skala.stock.service;

import com.skala.stock.dto.TradeSnapshotDto;
import com.skala.stock.entity.TradeAuditLog;
import com.skala.stock.entity.Transaction;
import com.skala.stock.mapper.StockMapper;
import com.skala.stock.repository.TradeAuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 거래 감사 로그를 별도 트랜잭션으로 저장한다.
 *
 * 왜 별도 빈인가:
 *   같은 클래스 안에서 @Transactional 메서드를 호출하면 프록시를 거치지 않아
 *   REQUIRES_NEW 가 적용되지 않는다(자기 호출 문제). 그래서 Aspect 가
 *   이 빈을 주입받아 호출하도록 분리했다.
 *
 * 왜 REQUIRES_NEW 인가:
 *   실패한 거래(잔액 부족 등)도 "시도했다"는 사실은 남아야 한다.
 *   거래 트랜잭션에 얹으면 롤백될 때 로그까지 사라진다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TradeAuditRecorder {

    private static final int MESSAGE_MAX = 500;

    private final TradeAuditLogRepository auditLogRepository;
    private final StockMapper stockMapper;

    /**
     * 감사 로그를 남긴다.
     *
     * 메시지뿐 아니라 <strong>그 시점의 총 자산·수익률 스냅샷</strong>도 함께 저장한다.
     * 나중에 로그만 보고도 "이 거래 직후 자산이 얼마였는지"를 알 수 있어야
     * 감사 기록으로서 쓸모가 있기 때문이다.
     * 스냅샷은 MyBatis 집계 쿼리(selectTradeSnapshot) 한 번으로 구한다.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(Long userId, Long stockId, Transaction.TransactionType type, String message) {
        try {
            TradeSnapshotDto snapshot = stockMapper.selectTradeSnapshot(userId);

            auditLogRepository.save(TradeAuditLog.builder()
                    .userId(userId)
                    .stockId(stockId)
                    .type(type)
                    .message(cut(message))
                    .totalAssets(snapshot == null ? null : snapshot.getTotalAssets())
                    .totalReturnRate(snapshot == null ? null : snapshot.getTotalReturnRate())
                    .build());
        } catch (Exception e) {
            // 감사 로그 저장이 실패해도 거래 결과에는 영향을 주지 않아야 한다
            log.warn("[AOP] 감사 로그 저장 실패: {}", e.getMessage());
        }
    }

    private String cut(String message) {
        if (message == null) {
            return "(내용 없음)";
        }
        return message.length() <= MESSAGE_MAX ? message : message.substring(0, MESSAGE_MAX - 3) + "...";
    }
}
