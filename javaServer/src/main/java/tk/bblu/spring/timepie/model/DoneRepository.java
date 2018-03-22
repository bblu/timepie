package tk.bblu.spring.timepie.model;

import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface DoneRepository extends MongoRepository<Done,String> {
    public List<Done> findByUser(String user);
}
