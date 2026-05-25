// main.c
#include <stdio.h>

// Include the generated headers for each entity
#include "Person.h"
#include "Product.h"
// #include "Order.h" // If you add an Order entity

int main() {
    printf("--- Generic Entity Linked List Demo ---\n");

    // --- Person Demo ---
    PersonNode *personList = NULL;
    PersonNode *p1_node = createPersonNode(1, "Alice", "Smith", 30);
    PersonNode *p2_node = createPersonNode(2, "Bob", "Johnson", 25);
    PersonNode *p3_node = createPersonNode(3, "Charlie", "Williams", 42);

    addPersonToList(&personList, p1_node);
    addPersonToList(&personList, p2_node);
    addPersonToList(&personList, p3_node);

    printPersonList(personList);
    freePersonList(&personList);
    printf("Person list after freeing:\n");
    printPersonList(personList); // Should be empty

    // --- Product Demo ---
    ProductNode *productList = NULL;
    ProductNode *prod1_node = createProductNode("SKU001", "Laptop Pro", 1200.50, 10);
    ProductNode *prod2_node = createProductNode("SKU002", "Wireless Mouse", 25.99, 50);

    addProductToList(&productList, prod1_node);
    addProductToList(&productList, prod2_node);

    printProductList(productList);
    freeProductList(&productList);
    printf("Product list after freeing:\n");
    printProductList(productList); // Should be empty

    /*
    // --- Order Demo (if Order entity is defined) ---
    OrderNode *orderList = NULL;
    OrderNode *ord1_node = createOrderNode(1001, 1, "2023-10-26");
    addOrderToList(&orderList, ord1_node);
    printOrderList(orderList);
    freeOrderList(&orderList);
    */

    printf("\nDemo finished.\n");
    return 0;
}
