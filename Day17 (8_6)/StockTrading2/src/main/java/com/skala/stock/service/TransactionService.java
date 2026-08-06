package com.skala.stock.service;

import com.skala.stock.dto.TradeRequestDto;
import com.skala.stock.dto.TransactionDto;
import com.skala.stock.entity.Portfolio;
import com.skala.stock.entity.Stock;
import com.skala.stock.entity.Transaction;
import com.skala.stock.entity.User;
import com.skala.stock.exception.BusinessRuleException;
import com.skala.stock.exception.ResourceNotFoundException;
import com.skala.stock.repository.StockRepository;
import com.skala.stock.repository.TransactionRepository;
import com.skala.stock.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final StockRepository stockRepository;
    private final PortfolioService portfolioService;

    /**
     * 주식 매수·매도를 실행한다.
     *
     * 하나의 트랜잭션 안에서 세 가지가 함께 바뀐다.
     *   1) 사용자 잔액   2) 포트폴리오 보유 수량·평균가   3) 거래 내역 기록
     * 중간에 실패하면 셋 다 함께 롤백되어야 하므로 @Transactional 로 묶는다.
     */
    @Transactional
    public TransactionDto executeTrade(TradeRequestDto request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> ResourceNotFoundException.of("사용자", request.getUserId()));
        Stock stock = stockRepository.findById(request.getStockId())
                .orElseThrow(() -> ResourceNotFoundException.of("주식", request.getStockId()));

        if (request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new BusinessRuleException("거래 수량은 1주 이상이어야 합니다: " + request.getQuantity());
        }

        long price = stock.getCurrentPrice();
        long totalAmount = price * request.getQuantity();

        if (request.getType() == Transaction.TransactionType.BUY) {
            buy(user, stock, request.getQuantity(), price, totalAmount);
        } else {
            sell(user, stock, request.getQuantity(), totalAmount);
        }

        Transaction transaction = transactionRepository.save(Transaction.builder()
                .user(user)
                .stock(stock)
                .type(request.getType())
                .quantity(request.getQuantity())
                .price(price)
                .totalAmount(totalAmount)
                .transactionDate(LocalDateTime.now())
                .build());

        return convertToDto(transaction);
    }

    private void buy(User user, Stock stock, Long quantity, long price, long totalAmount) {
        if (user.getBalance() < totalAmount) {
            throw new BusinessRuleException(
                    "잔액이 부족합니다. 필요 금액: " + totalAmount + ", 보유 금액: " + user.getBalance());
        }
        user.setBalance(user.getBalance() - totalAmount);
        userRepository.save(user);
        portfolioService.addToPortfolio(user, stock, quantity, price);
    }

    private void sell(User user, Stock stock, Long quantity, long totalAmount) {
        Portfolio holding = portfolioService.findHolding(user.getId(), stock.getId());
        long owned = (holding == null) ? 0 : holding.getQuantity();

        if (owned < quantity) {
            throw new BusinessRuleException(
                    "보유 수량이 부족합니다. 보유 수량: " + owned + ", 매도 수량: " + quantity);
        }
        user.setBalance(user.getBalance() + totalAmount);
        userRepository.save(user);
        portfolioService.removeFromPortfolio(holding, quantity);
    }

    /** 거래 상세 조회 — 읽기 전용 */
    @Transactional(readOnly = true)
    public TransactionDto getTransactionById(Long id) {
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("거래", id));
        return convertToDto(transaction);
    }

    @Transactional(readOnly = true, propagation = Propagation.SUPPORTS)
    public List<TransactionDto> getUserTransactions(Long userId) {
        return transactionRepository.findByUserIdOrderByTransactionDateDesc(userId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /** 사용자의 특정 주식 거래 내역만 조회한다. */
    @Transactional(readOnly = true)
    public List<TransactionDto> getUserStockTransactions(Long userId, Long stockId) {
        return transactionRepository
                .findByUserIdAndStockIdOrderByTransactionDateDesc(userId, stockId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    private TransactionDto convertToDto(Transaction transaction) {
        return TransactionDto.builder()
                .id(transaction.getId())
                .userId(transaction.getUser().getId())
                .username(transaction.getUser().getUsername())
                .stockId(transaction.getStock().getId())
                .stockCode(transaction.getStock().getCode())
                .stockName(transaction.getStock().getName())
                .type(transaction.getType())
                .quantity(transaction.getQuantity())
                .price(transaction.getPrice())
                .totalAmount(transaction.getTotalAmount())
                .transactionDate(transaction.getTransactionDate())
                .createdAt(transaction.getCreatedAt())
                .build();
    }
}
