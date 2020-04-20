-- 32 bit KSA

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use work.utility_functions.all;

entity rowReg is
port(
	d: in pg_row_type;
	en, clk, rst: in std_logic;
	q: out pg_row_type
	);
end rowReg;

architecture behavioral of rowReg is
begin

    process(clk) begin
        if (rising_edge(clk)) then
            if (en = '1') then
                q <= d;
            elsif (rst = '1') then
                q <= (others => '0');
            end if;
        end if;
    end process;

end behavioral;

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.utility_functions.all;

entity KSA is
port(
	a: in std_logic_vector(31 downto 0);
	b: in std_logic_vector(31 downto 0);
	clk, start, rst : in std_logic;
	done : out std_logic;
	s: out std_logic_vector(31 downto 0)
	);

end KSA;

architecture structural of KSA is
    
    signal p, g : pg_array_type;
    signal p_Reg, g_Reg : pg_array_type;
    
    signal stage_0_en, stage_1_en, stage_2_en, stage_3_en, stage_4_en, stage_5_en : std_logic;
    
    type ksa_state is (IDLE, STAGE_1, STAGE_2, STAGE_3, STAGE_4, STAGE_5);
        signal current_state : ksa_state;
        signal next_state : ksa_state;

begin

    public : process(start, current_state) begin
        
        -- Defaults:
        stage_0_en <= '0';
        stage_1_en <= '0';
        stage_2_en <= '0';
        stage_3_en <= '0';
        stage_4_en <= '0';
        stage_5_en <= '0';
        
        case current_state is
        when IDLE =>
            next_state <= IDLE;
            if (start = '1') then
                stage_0_en <= '1';
                next_state <= STAGE_1;
            end if;
            
        when STAGE_1 =>
            stage_1_en <= '1';
            next_state <= STAGE_2;
            
        when STAGE_2 =>
            stage_2_en <= '1';
            next_state <= STAGE_3;
            
        when STAGE_3 =>
            stage_3_en <= '1';
            next_state <= STAGE_4;
            
        when STAGE_4 =>
            stage_4_en <= '1';
            next_state <= STAGE_5;
            
        when STAGE_5 =>
            stage_5_en <= '1';
            next_state <= IDLE;
        
        when others =>
            next_state <= IDLE;
        end case;
    end process;
    
    sync_process: process(clk)
    begin
    if (rising_edge(clk)) then
       current_state <= next_state;
    end if;
    end process;
    
    done_process: process(clk)
    begin
    if (rising_edge(clk)) then
        done <= '0';
        if (stage_5_en = '1') then
            done <= '1';
        end if;
    end if;    
    end process;

    -- Registers
    p0_reg : entity work.rowReg(behavioral)
	port map(
        d => p(0),
        en => stage_0_en,
        rst => rst,
        clk => clk,
        q => p_Reg(0)
	);
	
	g0_reg : entity work.rowReg(behavioral)
	port map(
        d => g(0),
        en => stage_0_en,
        rst => rst,
        clk => clk,
        q => g_Reg(0)
	);
	
	p1_reg : entity work.rowReg(behavioral)
	port map(
        d => p(1),
        en => stage_1_en,
        rst => rst,
        clk => clk,
        q => p_Reg(1)
	);
	
	g1_reg : entity work.rowReg(behavioral)
	port map(
        d => g(1),
        en => stage_1_en,
        rst => rst,
        clk => clk,
        q => g_Reg(1)
	);

    p2_reg : entity work.rowReg(behavioral)
	port map(
        d => p(2),
        en => stage_2_en,
        rst => rst,
        clk => clk,
        q => p_Reg(2)
	);
	
	g2_reg : entity work.rowReg(behavioral)
	port map(
        d => g(2),
        en => stage_2_en,
        rst => rst,
        clk => clk,
        q => g_Reg(2)
	);
	
	p3_reg : entity work.rowReg(behavioral)
	port map(
        d => p(3),
        en => stage_3_en,
        rst => rst,
        clk => clk,
        q => p_Reg(3)
	);
	
	g3_reg : entity work.rowReg(behavioral)
	port map(
        d => g(3),
        en => stage_3_en,
        rst => rst,
        clk => clk,
        q => g_Reg(3)
	);
	
	p4_reg : entity work.rowReg(behavioral)
	port map(
        d => p(4),
        en => stage_4_en,
        rst => rst,
        clk => clk,
        q => p_Reg(4)
	);
	
	g4_reg : entity work.rowReg(behavioral)
	port map(
        d => g(4),
        en => stage_4_en,
        rst => rst,
        clk => clk,
        q => g_Reg(4)
	);
	
	p5_reg : entity work.rowReg(behavioral)
	port map(
        d => p(5),
        en => stage_5_en,
        rst => rst,
        clk => clk,
        q => p_Reg(5)
	);
	
	g5_reg : entity work.rowReg(behavioral)
	port map(
        d => g(5),
        en => stage_5_en,
        rst => rst,
        clk => clk,
        q => g_Reg(5)
	);
		
    -- Stage 0: Carry generation and propagation with mask refresh

    pg: for j in 0 to 31 generate
        g(0)(j) <= a(j) and b(j);
        p(0)(j) <= a(j) xor b(j);            
    end generate pg;

    -- Stage 1: Carry generation and propagation

    g(1)(0) <= g_Reg(0)(0);
    p(1)(0) <= p_Reg(0)(0);
    
    sj: for j in 1 to 31 generate
    
        g(1)(j) <= g_Reg(0)(j) xor (g_Reg(0)(j-1) and p_Reg(0)(j));
        p(1)(j) <= p_Reg(0)(j) and p_Reg(0)(j-1);
            
    end generate sj;
    
    -- Stages 2-5: Carry generation and propagation

    si: for i in 2 to 5 generate

        sk: for k in 0 to 2**(i-1)-1 generate
                
            g(i)(k) <= g_Reg(i-1)(k);
            p(i)(k) <= p_Reg(i-1)(k);
    
        end generate sk;
    
        sj: for j in 2**(i-1) to 31 generate
        
            g(i)(j) <= g_Reg(i-1)(j) xor (g_Reg(i-1)(j-2**(i-1)) and p_Reg(i-1)(j)); 
            p(i)(j) <= (p_Reg(I-1)(j) and p_Reg(i-1)(j-2**(i-1)));            
        
        end generate sj;

    end generate si;
  
    -- Addition stage:

    s(0) <= a(0) xor b(0);

    m1: for i in 1 to 31 generate

        s(i) <= a(i) xor b(i) xor g_Reg(5)(i-1); 

    end generate m1;

end structural;
