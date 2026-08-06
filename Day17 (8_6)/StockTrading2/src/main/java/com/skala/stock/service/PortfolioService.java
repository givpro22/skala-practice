package com.skala.stock.service;

import com.skala.stock.dto.PortfolioDto;
import com.skala.stock.entity.Portfolio;
import com.skala.stock.entity.Stock;
import com.skala.stock.entity.Transaction;
import com.skala.stock.entity.User;
import com.skala.stock.exception.ResourceNotFoundException;
import com.skala.stock.repository.PortfolioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PortfolioService {

    private final PortfolioRepository portfolioRepository;

    public List<PortfolioDto> getUserPortfolio(Long userId) {
        List<Portfolio> portfolios = portfolioRepository.findByUserId(userId);
        return portfolios.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * 사용자가 보유한 특정 주식의 포트폴리오를 조회한다.
     * 보유하고 있지 않으면 404를 반환한다.
     */
    public PortfolioDto getPortfolio(Long userId, Long stockId) {
        Portfolio portfolio = portfolioRepository.findByUserIdAndStockId(userId, stockId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "보유 중인 주식이 아닙니다. userId=" + userId + ", stockId=" + stockId));
        return convertToDto(portfolio);
    }

    /**
     * 매수 시 포트폴리오를 갱신한다.
     *
     * 이미 보유 중이면 평균 매수가를 다시 계산한다.
     *   새 평균가 = (기존 평가액 + 이번 매수액) / (기존 수량 + 이번 수량)
     */
    @Transactional
    public void addToPortfolio(User user, Stock stock, Long quantity, Long price) {
        Portfolio portfolio = portfolioRepository
                .findByUserIdAndStockId(user.getId(), stock.getId())
                .orElse(null);

        if (portfolio == null) {
            portfolioRepository.save(Portfolio.builder()
                    .user(user).stock(stock)
                    .quantity(quantity).averagePrice(price)
                    .build());
            return;
        }

        long beforeAmount = portfolio.getQuantity() * portfolio.getAveragePrice();
        long addedAmount = quantity * price;
        long totalQuantity = portfolio.getQuantity() + quantity;

        portfolio.setAveragePrice((beforeAmount + addedAmount) / totalQuantity);
        portfolio.setQuantity(totalQuantity);
        portfolioRepository.save(portfolio);
    }

    /**
     * 매도 시 포트폴리오를 갱신한다.
     * 남은 수량이 0이면 보유 목록에서 제거한다. (평균 매수가는 매도로 바뀌지 않는다)
     */
    @Transactional
    public void removeFromPortfolio(Portfolio portfolio, Long quantity) {
        long remaining = portfolio.getQuantity() - quantity;
        if (remaining == 0) {
            portfolioRepository.delete(portfolio);
            return;
        }
        portfolio.setQuantity(remaining);
        portfolioRepository.save(portfolio);
    }

    /** 매도 가능 여부 확인에 쓰는 조회 (없으면 null) */
    public Portfolio findHolding(Long userId, Long stockId) {
        return portfolioRepository.findByUserIdAndStockId(userId, stockId).orElse(null);
    }

    private PortfolioDto convertToDto(Portfolio portfolio) {
        Stock stock = portfolio.getStock();
        Long currentPrice = stock.getCurrentPrice();
        Long totalValue = portfolio.getQuantity() * currentPrice;
        Long profitLoss = totalValue - (portfolio.getQuantity() * portfolio.getAveragePrice());

        return PortfolioDto.builder()
                .id(portfolio.getId())
                .userId(portfolio.getUser().getId())
                .username(portfolio.getUser().getUsername())
                .stockId(stock.getId())
                .stockCode(stock.getCode())
                .stockName(stock.getName())
                .quantity(portfolio.getQuantity())
                .averagePrice(portfolio.getAveragePrice())
                .currentPrice(currentPrice)
                .totalValue(totalValue)
                .profitLoss(profitLoss)
                .build();
    }
}
