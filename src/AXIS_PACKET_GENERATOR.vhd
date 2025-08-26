
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity AXIS_PACKET_GENERATOR is
	generic (
		tDATA_WIDTH					: integer := 8;
		PACKET_TO_SEND      		: string  := "123456"; -- in hex
		Specific_Number_Of_Packets  : boolean := true; 
		Number_Of_Packets_To_Send	: integer := 10
	);
	port (

		SEND_PACKET		: in std_logic;
		M_AXIS_ACLK		: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_tREADY	: in std_logic; -- its not implemented
		M_AXIS_tDATA 	: out std_logic_vector(tDATA_WIDTH-1 downto 0); 
		M_AXIS_tVALID 	: out std_logic; 
		M_AXIS_tLAST	: out std_logic 

	);
end AXIS_PACKET_GENERATOR;


architecture arch_imp of AXIS_PACKET_GENERATOR is
    
	subtype slv is std_logic_vector;
-------------------------------------------------------------------------------------
------ This function converts strings to binary with std_logic_vector type ----------
------------------------------------------------------------------------------------- 

function to_slv(s: string) return std_logic_vector is 
	constant ss: string(1 to s'length) := s; 
	variable answer: std_logic_vector(1 to 8 * s'length); 
	variable f_answer: std_logic_vector(1 to 4 * s'length); 
    variable p: integer; 
    variable c: integer; 
    variable d: integer; 
begin 
    for i in ss'range loop
        p := 8 * i;
        d := 4 * i;
        c := character'pos(ss(i));
        answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
        --- translate it to hex --- 
		if(unsigned(answer(p - 7 to p-4)) = 3) then --- numbers
			f_answer(d-3 to d)	:= answer(p - 3 to p); --- only 4-bit lsb
		elsif(unsigned(answer(p - 7 to p-4)) = 4) then--- letters
			f_answer(d-3 to d)	:= std_logic_vector(unsigned(answer(p - 3 to p)) + 9); --- only 4-bit lsb + 9
		end if;
    end loop; 
    return f_answer;
end function;

constant msb_bit_cnt : integer := PACKET_TO_SEND'length*4;
constant HEX_SPECIAL_PACKET : STD_LOGIC_VECTOR(msb_bit_cnt-1 downto 0) := to_slv(PACKET_TO_SEND); 


constant packet_word_cnt : integer := msb_bit_cnt/tDATA_WIDTH; 
constant Wcnt : integer := packet_word_cnt-1; 

signal index 			: integer := 0; 
signal Packet_cnt 		: integer := 0; 
signal S_AXIS_tLAST_INT : std_logic := '0'; 
signal SEND_PACKET_INT  : std_logic := '0'; 

type StateType is (Idle,Send1);
signal FSM : StateType := idle;

begin

M_AXIS_tLAST   <= S_AXIS_tLAST_INT;
Specific_Number_Of_Packets_con: if(Specific_Number_Of_Packets=true) generate
process(M_AXIS_ACLK)
begin
	if rising_edge(M_AXIS_ACLK) then 
		if ( M_AXIS_ARESETN = '0' ) then
				M_AXIS_tVALID   <= '0'; 
				Packet_cnt		<= 0;
				index			<= 0;
				FSM				<= Idle;
		else 		
			SEND_PACKET_INT		<= SEND_PACKET;	
				M_AXIS_tVALID  		<= '0'; 
			S_AXIS_tLAST_INT	<= '0'; 		
			case FSM is 
				when idle => 
						if(SEND_PACKET='1' and SEND_PACKET_INT='0') then 
						FSM	<= Send1;
					end if; 
				when Send1 => 
						M_AXIS_tVALID  	<= '1'; 		
						M_AXIS_tDATA	<= HEX_SPECIAL_PACKET(tDATA_WIDTH*(Wcnt-index+1)-1 downto tDATA_WIDTH*(Wcnt-index+1)-tDATA_WIDTH);	
						index			<= index +1; 
						if(index=Wcnt)then 
							index				<= 0;
							Packet_cnt			<= Packet_cnt +1;
							S_AXIS_tLAST_INT	<= '1'; 
						end if; 
						if(Packet_cnt=Number_Of_Packets_To_Send) then 
							Packet_cnt	  <= 0;
							FSM			   <= Idle;
							M_AXIS_tVALID  	<= '0'; 						
						end if; 	
				when others => 
			end case ;
		end if; 
	end if;
end process;
end generate Specific_Number_Of_Packets_con;


nSpecific_Number_Of_Packets_con: if(Specific_Number_Of_Packets=false) generate
	process(M_AXIS_ACLK)
	begin
		if rising_edge(M_AXIS_ACLK) then 
			if ( M_AXIS_ARESETN = '0' ) then
				M_AXIS_tVALID   <= '0'; 
				Packet_cnt		<= 0;
				index			<= 0;
				FSM				<= Idle;
			else 		
				SEND_PACKET_INT		<= SEND_PACKET;	
				M_AXIS_tVALID  		<= '0'; 
				S_AXIS_tLAST_INT	<= '0'; 		
				case FSM is 
					when idle => 
						if(SEND_PACKET='1') then 
							FSM	<= Send1;
						end if; 
					when Send1 => 
						M_AXIS_tVALID  	<= '1'; 		
						M_AXIS_tDATA	<= HEX_SPECIAL_PACKET(tDATA_WIDTH*(Wcnt-index+1)-1 downto tDATA_WIDTH*(Wcnt-index+1)-tDATA_WIDTH);	
						index			<= index +1; 
						if(index=Wcnt)then 
                            index				<= 0;
                            S_AXIS_tLAST_INT	<= '1'; 
                            FSM					<= Idle;
                       end if; 
					when others => 
				end case ;
			end if; 
		end if;
	end process;
end generate nSpecific_Number_Of_Packets_con;
end arch_imp;
