package com.skala.stock.repository;

import com.skala.stock.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByUserIdOrderByTransactionDateDesc(Long userId);
    List<Transaction> findByUserIdAndStockIdOrderByTransactionDateDesc(Long userId, Long stockId);

    // 삭제 전 참조 검사용 (transactions.user_id / stock_id 는 NOT NULL FK)
    boolean existsByUserId(Long userId);
    boolean existsByStockId(Long stockId);
}
