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

        return convertToDto(stockRepository.save(stock));
    }

    public StockDto getStockById(Long id) {
        return convertToDto(findStockOrThrow(id));
    }

    /**
     * 종목 코드로 주식을 조회한다.
     *
     * id는 DB가 부여한 값이라 외부에서 알기 어렵지만
     * 종목 코드("005930")는 사용자가 아는 값이므로 별도 조회 경로를 둔다.
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
     * 주식 정보를 수정한다.
     *
     * 종목 코드는 다른 종목이 이미 쓰고 있으면 바꿀 수 없다.
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

        return convertToDto(stockRepository.save(stock));
    }

    /**
     * 주식을 삭제한다.
     *
     * 포트폴리오나 거래 내역이 참조 중이면 삭제할 수 없다.
     * 그대로 지우면 NOT NULL 외래키 제약에 걸려 500이 나므로 미리 막는다.
     */
    @Transactional
    public void deleteStock(Long id) {
        Stock stock = findStockOrThrow(id);

        if (portfolioRepository.existsByStockId(id)) {
            throw new ResourceInUseException("보유 중인 포트폴리오가 있어 삭제할 수 없습니다: " + stock.getCode());
        }
        if (transactionRepository.existsByStockId(id)) {
            throw new ResourceInUseException("거래 내역이 있어 삭제할 수 없습니다: " + stock.getCode());
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
