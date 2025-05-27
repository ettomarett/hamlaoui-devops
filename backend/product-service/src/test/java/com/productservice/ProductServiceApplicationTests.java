package com.productservice;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.productservice.dto.ProductRequest;
import com.productservice.repository.ProductRepository;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProductServiceApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ProductRepository productRepository;

    private ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void contextLoads() {
        // Simple context loading test
        // This will use embedded MongoDB instead of Testcontainers
    }

    @Test
    void shouldCreateProduct() throws Exception {
        ProductRequest productRequest = getProductRequest();
        String productRequestString = objectMapper.writeValueAsString(productRequest);

        mockMvc.perform(MockMvcRequestBuilders.post("/api/product/create")
                        .contentType("application/json")
                        .content(productRequestString))
                .andExpect(status().isCreated());
        
        Assertions.assertEquals(1, productRepository.findAll().size());
    }

    @Test
    void shouldFetchAllProduct() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders.get("/api/product/allProducts")
                        .accept("application/json"))
                .andExpect(status().isOk());
    }

    private ProductRequest getProductRequest() {
        return ProductRequest.builder()
                .name("iphone 13")
                .description("iphone 13 mini")
                .price(BigDecimal.valueOf(500000))
                .build();
    }
}
