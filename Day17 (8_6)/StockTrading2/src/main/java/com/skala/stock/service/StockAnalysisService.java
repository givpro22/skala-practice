package com.skala.stock.service;

import com.skala.stock.dto.AssetSummaryDto;
import com.skala.stock.dto.PortfolioDto;
import com.skala.stock.dto.ReturnRateDto;
import com.skala.stock.dto.TransactionDto;
import com.skala.stock.entity.TradeAuditLog;
import com.skala.stock.entity.User;
import com.skala.stock.exception.ResourceNotFoundException;
import com.skala.stock.mapper.DailyTradeDto;
import com.skala.stock.mapper.StockMapper;
import com.skala.stock.mapper.TransactionStatisticsDto;
import com.skala.stock.repository.TradeAuditLogRepository;
import com.skala.stock.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 분석·통계 기능을 담당한다.
 *
 * 단순 조회는 JPA(Repository)를, GROUP BY가 필요한 집계는 MyBatis(Mapper)를 쓴다.
 * 같은 데이터라도 "무엇을 묻느냐"에 따라 도구를 나눈 것이다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StockAnalysisService {

    private final StockMapper stockMapper;
    private final UserRepository userRepository;
    private final TradeAuditLogRepository auditLogRepository;
    private final PortfolioService portfolioService;
    private final TransactionService transactionService;

    /** ① 포트폴리오 평가 손익 조회 — 종목별 평가액과 손익 */
    public List<PortfolioDto> getPortfolioProfitLoss(Long userId) {
        requireUser(userId);
        return portfolioService.getUserPortfolio(userId);
    }

    /** ② 거래 내역 상세 조회 */
    public List<TransactionDto> getTransactionDetails(Long userId) {
        requireUser(userId);
        return transactionService.getUserTransactions(userId);
    }

    /** ③ 특정 주식 거래 내역 조회 */
    public List<TransactionDto> getStockTransactions(Long userId, Long stockId) {
        requireUser(userId);
        return transactionService.getUserStockTransactions(userId, stockId);
    }

    /**
     * ④ 총 자산 조회 — 현금 + 보유 주식 평가액
     * 평가액·원가 합계는 MyBatis 집계 쿼리로 구한다.
     */
    public AssetSummaryDto getTotalAssets(Long userId) {
        User user = requireUser(userId);

        long holdingValue = nullToZero(stockMapper.selectHoldingValue(userId));
        long holdingCost = nullToZero(stockMapper.selectHoldingCost(userId));

        return AssetSummaryDto.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .cashBalance(user.getBalance())
                .holdingValue(holdingValue)
                .totalAssets(user.getBalance() + holdingValue)
                .holdingCost(holdingCost)
                .evaluationProfit(holdingValue - holdingCost)
                .build();
    }

    /**
     * ⑤ 총 수익률 조회 — 평가 손익 / 매입 원가 × 100
     * 보유 주식이 없으면 원가가 0이라 나눌 수 없으므로 0%로 본다.
     */
    public ReturnRateDto getTotalReturnRate(Long userId) {
        User user = requireUser(userId);

        long holdingValue = nullToZero(stockMapper.selectHoldingValue(userId));
        long holdingCost = nullToZero(stockMapper.selectHoldingCost(userId));
        long profit = holdingValue - holdingCost;

        double rate = (holdingCost == 0) ? 0.0
                : Math.round((profit * 10000.0) / holdingCost) / 100.0; // 소수 둘째 자리

        return ReturnRateDto.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .holdingCost(holdingCost)
                .holdingValue(holdingValue)
                .evaluationProfit(profit)
                .returnRate(rate)
                .build();
    }

    /** ⑥ 거래 통계 조회 — 종목별 매수/매도 집계 (MyBatis) */
    public List<TransactionStatisticsDto> getTransactionStatistics(Long userId) {
        requireUser(userId);
        return stockMapper.selectTransactionStatistics(userId);
    }

    /** ⑦ 일별 거래 내역 조회 — 날짜별 집계 (MyBatis) */
    public List<DailyTradeDto> getDailyTrades(Long userId) {
        requireUser(userId);
        return stockMapper.selectDailyTrades(userId);
    }

    /**
     * ⑧ 거래 감사 로그 조회 — AOP가 남긴 기록
     *
     * TradeAuditAspect 가 매매 성공·실패 시마다 남긴 로그다.
     * 실패한 거래도 별도 트랜잭션(REQUIRES_NEW)으로 저장되므로 함께 조회된다.
     */
    public List<TradeAuditLog> getAuditLogs(Long userId) {
        requireUser(userId);
        return auditLogRepository.findByUserIdOrderByIdDesc(userId);
    }

    /**
     * 분석 API는 모두 사용자 기준이므로, 없는 사용자면 빈 결과 대신 404를 준다.
     * 빈 배열을 돌려주면 "거래가 없는 것"과 "사용자가 없는 것"을 구분할 수 없다.
     */
    private User requireUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> ResourceNotFoundException.of("사용자", userId));
    }

    private long nullToZero(Long value) {
        return value == null ? 0L : value;
    }
}
