#include "xil_printf.h"
#include "xil_io.h"
#include "xil_types.h"
#include <stdint.h>

#define CORDIC_BASE_ADDR   0x43C00000U

#define REG_CONTROL        0x00U
#define REG_STATUS         0x04U
#define REG_ANGLE_IN       0x08U
#define REG_SIN_OUT        0x0CU
#define REG_COS_OUT        0x10U

#define CONTROL_START      0x1U
#define CONTROL_DONE_ACK   0x2U

#define STATUS_DONE        0x2U

#define TOL_LSB            16

typedef struct {
    const char *name;
    u16 angle_q214;
    int16_t exp_sin;
    int16_t exp_cos;
} cordic_test_t;

static int16_t sign16(u32 value)
{
    return (int16_t)(value & 0xFFFFU);
}

static int abs_int(int x)
{
    return (x < 0) ? -x : x;
}

static int run_cordic_test(const cordic_test_t *test)
{
    u32 status;
    u32 timeout = 1000000U;

    Xil_Out32(CORDIC_BASE_ADDR + REG_CONTROL, CONTROL_DONE_ACK);
    Xil_Out32(CORDIC_BASE_ADDR + REG_ANGLE_IN, test->angle_q214);
    Xil_Out32(CORDIC_BASE_ADDR + REG_CONTROL, CONTROL_START);

    do {
        status = Xil_In32(CORDIC_BASE_ADDR + REG_STATUS);

        if (timeout == 0U) {
            xil_printf("FAIL %-14s timeout STATUS=0x%08x\r\n", test->name, status);
            return 0;
        }

        timeout--;
    } while ((status & STATUS_DONE) == 0U);

    int16_t sin_q214 = sign16(Xil_In32(CORDIC_BASE_ADDR + REG_SIN_OUT));
    int16_t cos_q214 = sign16(Xil_In32(CORDIC_BASE_ADDR + REG_COS_OUT));

    int sin_err = abs_int((int)sin_q214 - (int)test->exp_sin);
    int cos_err = abs_int((int)cos_q214 - (int)test->exp_cos);

    int pass = (sin_err <= TOL_LSB) && (cos_err <= TOL_LSB);

    xil_printf("%s %-14s angle=0x%04x "
               "sin=0x%04x/%d exp=%d err=%d "
               "cos=0x%04x/%d exp=%d err=%d STATUS=0x%08x\r\n",
               pass ? "PASS" : "FAIL",
               test->name,
               test->angle_q214,
               (u16)sin_q214, sin_q214, test->exp_sin, sin_err,
               (u16)cos_q214, cos_q214, test->exp_cos, cos_err,
               status);

    Xil_Out32(CORDIC_BASE_ADDR + REG_CONTROL, CONTROL_DONE_ACK);

    return pass;
}

int main(void)
{
    cordic_test_t tests[] = {
        {"0 rad",      0x0000,      0,      16384},
        {"+pi/4",      0x3244,  11585,      11585},
        {"-pi/4",      0xCDBC, -11585,      11585},
        {"+pi/2",      0x6488,  16384,          0},
        {"-pi/2",      0x9B78, -16384,          0},
    };

    int total = sizeof(tests) / sizeof(tests[0]);
    int pass_count = 0;

    xil_printf("\r\n==============================\r\n");
    xil_printf("ZedBoard CORDIC AXI-Lite Demo\r\n");
    xil_printf("==============================\r\n");
    xil_printf("Base address: 0x%08x\r\n", CORDIC_BASE_ADDR);
    xil_printf("Tolerance   : +/- %d LSB\r\n\r\n", TOL_LSB);

    for (int i = 0; i < total; i++) {
        pass_count += run_cordic_test(&tests[i]);
    }

    xil_printf("\r\nSummary: %d/%d tests passed\r\n", pass_count, total);

    if (pass_count == total) {
        xil_printf("CORDIC ZedBoard hardware validation PASSED\r\n");
    } else {
        xil_printf("CORDIC ZedBoard hardware validation FAILED\r\n");
    }

    while (1) {
    }

    return 0;
}