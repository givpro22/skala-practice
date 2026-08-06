package com.skala.stock.service;

import com.skala.stock.dto.StockDto;
import com.skala.stock.entity.Stock;
import com.skala.stock.exception.DuplicateResourceException;
import com.skala.stock.exception.ResourceInUseException;
import com.skala.stock.exception.ResourceNotFoundException;
import com.skala.stock.repository.PortfolioRepository;
import com.skala.stock.repository.StockRepository;
import com.skala.stock.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StockService {

    private final StockRepository stockRepository;
    private final PortfolioRepository portfolioRepository;
    private final TransactionRepository transactionRepository;

    @Transactional
    public StockDto createStock(StockDto stockDto) {
        if (stockRepository.existsByCode(stockDto.getCode())) {
            throw new DuplicateResourceException("이미 존재하는 종목 코드입니다: " + stockDto.getCode());
        }

        Stock stock = Stock.builder()
                .code(stockDto.getCode())
                .name(stockDto.getName())
                .currentPrice(stockDto.getCurrentPrice())
                .previousPrice(stockDto.getPreviousPrice())
                .build();

        Stock savedStock = stockRepository.save(stock);
        return convertToDto(savedStock);
    }

    public StockDto getStockById(Long id) {
        return convertToDto(findStockOrThrow(id));
    }

    /**
     * 종목 코드로 주식을 조회합니다.
     * ID는 DB가 부여한 값이라 외부에서 알기 어렵지만, 종목 코드("005930")는
     * 사용자가 아는 값이므로 별도 조회 경로를 둡니다.
     */
    public StockDto getStockByCode(String code) {
        Stock stock = stockRepository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("주식을 찾을 수 없습니다. 종목 코드: " + code));
        return convertToDto(stock);
    }

    public List<StockDto> getAllStocks() {
        return stockRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * 주식 정보를 수정합니다.
     *
     * 종목 코드는 다른 종목이 이미 쓰고 있으면 바꿀 수 없습니다.
     * (자기 자신이 쓰던 코드를 그대로 보내는 것은 허용)
     */
    @Transactional
    public StockDto updateStock(Long id, StockDto stockDto) {
        Stock stock = findStockOrThrow(id);

        if (!stock.getCode().equals(stockDto.getCode())
                && stockRepository.existsByCode(stockDto.getCode())) {
            throw new DuplicateResourceException("이미 존재하는 종목 코드입니다: " + stockDto.getCode());
        }

        stock.setCode(stockDto.getCode());
        stock.setName(stockDto.getName());
        stock.setCurrentPrice(stockDto.getCurrentPrice());
        stock.setPreviousPrice(stockDto.getPreviousPrice());

        // 조회한 엔티티는 영속 상태이므로 트랜잭션이 끝날 때 변경 감지로 UPDATE가 나갑니다.
        // save()를 부르지 않아도 반영되지만, 의도를 드러내기 위해 명시적으로 호출합니다.
        return convertToDto(stockRepository.save(stock));
    }

    /**
     * 주식을 삭제합니다.
     *
     * 포트폴리오나 거래 내역이 이 종목을 참조하고 있으면 삭제할 수 없습니다.
     * 그대로 지우면 NOT NULL 외래키 제약에 걸려 500이 나므로 미리 막습니다.
     */
    @Transactional
    public void deleteStock(Long id) {
        Stock stock = findStockOrThrow(id);

        if (portfolioRepository.existsByStockId(id)) {
            throw new ResourceInUseException(
                    "보유 중인 포트폴리오가 있어 삭제할 수 없습니다: " + stock.getCode());
        }
        if (transactionRepository.existsByStockId(id)) {
            throw new ResourceInUseException(
                    "거래 내역이 있어 삭제할 수 없습니다: " + stock.getCode());
        }

        stockRepository.delete(stock);
    }

    private Stock findStockOrThrow(Long id) {
        return stockRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("주식", id));
    }

    private StockDto convertToDto(Stock stock) {
        return StockDto.builder()
                .id(stock.getId())
                .code(stock.getCode())
                .name(stock.getName())
                .currentPrice(stock.getCurrentPrice())
                .previousPrice(stock.getPreviousPrice())
                .build();
    }
}
