package com.skala.stock.repository;

import com.skala.stock.entity.Portfolio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PortfolioRepository extends JpaRepository<Portfolio, Long> {
    List<Portfolio> findByUserId(Long userId);
    Optional<Portfolio> findByUserIdAndStockId(Long userId, Long stockId);
    boolean existsByUserIdAndStockId(Long userId, Long stockId);

    // 삭제 전 참조 검사용 (portfolios.user_id / stock_id 는 NOT NULL FK)
    boolean existsByUserId(Long userId);
    boolean existsByStockId(Long stockId);
}
