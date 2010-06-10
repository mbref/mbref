/*
 * FILE:
 *     time.c
 *
 * DESCRIPTION:
 *     Microblaze arch Timer/Counter routines for Xilinx's OPB Timer.
 *     This code is designed to work with a 32-bit upcounting timer in 
 *     polled mode.   
 *     
 *     Note: 
 *     Timer enable and configuration code is done in the first-stage.
 *     bootloader before U-Boot is started.  
 *
 * AUTHOR:
 *     Benny Chen   <benny.chen@petalogix.com>
 *
 * MODIFICATION:
 *
 * LICENSING:
 *     Copyright (c) 2006 PetaLogix. All rights reserved.
 *
 *  This program is free software; you can redistribute  it and/or modify it
 *  under  the terms of  the GNU General Public License as published by the
 *  Free Software Foundation;  either version 2 of the  License, or (at your
 *  option) any later version.
 *
 *  THIS  SOFTWARE  IS PROVIDED   ``AS  IS'' AND   ANY  EXPRESS OR IMPLIED
 *  WARRANTIES,   INCLUDING, BUT NOT  LIMITED  TO, THE IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN
 *  NO  EVENT  SHALL   THE AUTHOR  BE    LIABLE FOR ANY   DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED   TO, PROCUREMENT OF  SUBSTITUTE GOODS  OR SERVICES; LOSS OF
 *  USE, DATA,  OR PROFITS; OR  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  You should have received a copy of the  GNU General Public License along
 *  with this program; if not, write  to the Free Software Foundation, Inc.,
 *  675 Mass Ave, Cambridge, MA 02139, USA.
 */
#include "fs-boot.h"

/* 
 * 32-bit timer roll over value 
 * FIXME -Assume 32-bit counter, we probably want
 *        to auto-config out this value.
 */
#define TIMER_MAX       0xFFFFFFFF

static unsigned long timestamp;
static unsigned long lastinc;

void reset_timer_masked (void)
{
    /* Reset time keeping variables */
    lastinc = REG32_READ(TIMER_BASE, O_TIMER_TCR0);
    timestamp = 0;
}

void reset_timer (void)
{
    reset_timer_masked();
}

unsigned long get_timer_masked (void)
{
    unsigned long now = REG32_READ(TIMER_BASE, O_TIMER_TCR0);

    if (lastinc <= now) {
        /* Normal count up mode */
        timestamp += (now - lastinc);
    } else {
        /* Overflow mode */
        timestamp += (TIMER_MAX - lastinc) + now;
    }
    lastinc = now;

    return timestamp;
}

unsigned long   get_timer (unsigned long base)
{
    return (get_timer_masked() - base);
}

void set_timer (unsigned long t)
{
    timestamp = t;
}

void udelay(unsigned long usec)
{
    unsigned long tmo, tmp;

    if (usec >= 1000) {
        /* Prevent overflowing 32-bit word */
        tmo = usec / 1000;
        tmo *= CFG_HZ;
        tmo /= 1000;
    } else {
        /* Prevent smaller usec from being zeroed out */
        tmo = (usec * CFG_HZ);
        tmo /= (1000 * 1000);
    }

    tmp = get_timer(0);    /* Get current timestamp */
    if ((tmo + tmp +1) < tmp) {
        /* Adding ticks overflow the timestamp variable */
        reset_timer_masked();
    } else {
        /* Normal no overflow */
        tmo += tmp;
    }

    /* Wait till the number of tick is expired */
    while (get_timer_masked() < tmo);

}

int timer_init (void)
{
    /* Setup the timer load register with reset value */
    REG32_WRITE(TIMER_BASE + O_TIMER_TLR0, TIMER_RESET_VALUE);

    /*
     * Initialised the timer to default value
     * The default settings for the timers are:
     *   - Interrupt generation disabled
     *   - Count up mode
     *   - Compare mode
     *   - Enable Auto Reload
     *   - External compare output disabled
     *   - External capture input disabled
     *   - Pulse width modulation disabled
     *   - Timer disabled, waits for Start function to be called
     */
    REG32_WRITE(TIMER_BASE + O_TIMER_TCSR0, TIMER_TCSR0_INIT);

    return (0);
}


